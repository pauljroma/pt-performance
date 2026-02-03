import SwiftUI

// MARK: - 1RM Calculator View (ACP-512)

/// Estimates one-rep max using the Epley formula and shows a percentage breakdown table.
struct OneRepMaxCalculatorView: View {

    // MARK: - State

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var formulaExpanded: Bool = false

    // MARK: - Computed Properties

    /// Parsed weight from user input.
    private var weight: Double? {
        Double(weightText)
    }

    /// Parsed reps from user input, clamped to 1-30.
    private var reps: Int? {
        guard let value = Int(repsText), value >= 1, value <= 30 else { return nil }
        return value
    }

    /// Estimated 1RM using the Epley formula.
    /// For 1 rep the 1RM equals the weight lifted.
    private var estimatedOneRepMax: Double? {
        guard let weight, let reps, weight > 0 else { return nil }
        if reps == 1 {
            return weight
        }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Rounds a value to the nearest 2.5 lbs.
    private func roundToPlate(_ value: Double) -> Double {
        (value / 2.5).rounded() * 2.5
    }

    /// Percentage breakdown rows for the table.
    private var percentageRows: [(label: String, percentage: Double, repRange: String)] {
        [
            ("100%", 1.00, "1 rep (1RM)"),
            ("95%",  0.95, "~2 reps"),
            ("90%",  0.90, "~3 reps"),
            ("85%",  0.85, "~5 reps"),
            ("80%",  0.80, "~6-8 reps"),
            ("75%",  0.75, "~8-10 reps"),
            ("70%",  0.70, "~10-12 reps"),
            ("65%",  0.65, "~12-15 reps"),
            ("60%",  0.60, "~15-20 reps")
        ]
    }

    // MARK: - Body

    var body: some View {
        Form {
            inputSection
            resultSection
            percentageBreakdownSection
            formulaSection
            clearSection
        }
        .navigationTitle("1RM Calculator")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        Section {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                TextField("Weight lifted (lbs)", text: $weightText)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Weight lifted in pounds")
            }

            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                TextField("Reps performed (1-30)", text: $repsText)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Repetitions performed, 1 through 30")
            }
        } header: {
            Text("Lift Details")
        } footer: {
            Text("Enter the weight and number of reps you performed.")
        }
    }

    // MARK: - Result Section

    @ViewBuilder
    private var resultSection: some View {
        if let oneRM = estimatedOneRepMax {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)

                    Text("Estimated 1RM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(roundToPlate(oneRM), specifier: "%.1f") lbs")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if let reps, reps > 1 {
                        Text("Based on \(weightText) lbs x \(reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Estimated one rep max: \(roundToPlate(oneRM), specifier: "%.1f") pounds")
            }
        }
    }

    // MARK: - Percentage Breakdown

    @ViewBuilder
    private var percentageBreakdownSection: some View {
        if let oneRM = estimatedOneRepMax {
            Section {
                ForEach(percentageRows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(width: 50, alignment: .leading)

                        Spacer()

                        Text("\(roundToPlate(oneRM * row.percentage), specifier: "%.1f") lbs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()

                        Spacer()

                        Text(row.repRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.label): \(roundToPlate(oneRM * row.percentage), specifier: "%.1f") pounds, \(row.repRange)")
                }
            } header: {
                Text("Percentage Breakdown")
            } footer: {
                Text("Weights are rounded to the nearest 2.5 lbs for standard plate loading.")
            }
        }
    }

    // MARK: - Formula Section

    private var formulaSection: some View {
        Section {
            DisclosureGroup("About the Formula", isExpanded: $formulaExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Epley Formula")
                        .font(.headline)

                    Text("1RM = weight x (1 + reps / 30)")
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)

                    Text("The Epley formula is one of the most widely used methods for estimating one-rep max from submaximal lifts. It provides a reasonable estimate for most compound exercises when reps are between 2 and 10.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("For a single rep, the 1RM is simply the weight lifted. The formula becomes less accurate at very high rep ranges (above 15).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Clear Section

    private var clearSection: some View {
        Section {
            Button(role: .destructive) {
                clearAll()
            } label: {
                HStack {
                    Spacer()
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                    Spacer()
                }
            }
            .disabled(weightText.isEmpty && repsText.isEmpty)
            .accessibilityLabel("Clear all fields")
            .accessibilityHint("Resets weight and reps to empty")
        }
    }

    // MARK: - Actions

    private func clearAll() {
        weightText = ""
        repsText = ""
        formulaExpanded = false
    }
}

// MARK: - Preview

#Preview {
    OneRepMaxCalculatorView()
}
