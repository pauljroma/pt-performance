import SwiftUI

/// Supplement Log View - Quick supplement logging
struct SupplementLogView: View {
    @Environment(\.dismiss) private var dismiss

    let preselectedSupplement: Supplement?
    let onSave: (SupplementLogEntry) -> Void

    @State private var selectedTiming: SupplementTiming = .morning
    @State private var dosageAmount: String = ""
    @State private var withFood: Bool = false
    @State private var notes: String = ""
    @State private var perceivedEffect: PerceivedEffect?

    init(preselectedSupplement: Supplement? = nil, onSave: @escaping (SupplementLogEntry) -> Void) {
        self.preselectedSupplement = preselectedSupplement
        self.onSave = onSave
        // Pre-fill dosage from preselected supplement
        if let supplement = preselectedSupplement {
            _dosageAmount = State(initialValue: supplement.dosage)
            _withFood = State(initialValue: supplement.withFood)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Show which supplement is being logged
                if let supplement = preselectedSupplement {
                    Section {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: supplement.category.icon)
                                .font(.title3)
                                .foregroundColor(.modusCyan)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(supplement.name)
                                    .font(.headline)
                                    .foregroundColor(.modusDeepTeal)

                                if let brand = supplement.brand {
                                    Text(brand)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text(supplement.category.displayName)
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(Color.modusCyan.opacity(0.1))
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Logging \(supplement.name)\(supplement.brand.map { " by \($0)" } ?? "")")
                }

                Section("Dosage") {
                    TextField("Amount (e.g., 500mg)", text: $dosageAmount)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Dosage amount")
                        .accessibilityHint("Enter the dosage, for example 500mg")
                }

                Section("Timing") {
                    Picker("Time of Day", selection: $selectedTiming) {
                        ForEach(SupplementTiming.allCases) { timing in
                            Text(timing.displayName).tag(timing)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("With Food", isOn: $withFood)
                }

                Section("How did it feel?") {
                    Picker("Perceived Effect", selection: Binding(
                        get: { perceivedEffect ?? .neutral },
                        set: { perceivedEffect = $0 }
                    )) {
                        ForEach(PerceivedEffect.allCases, id: \.self) { effect in
                            Text(effect.displayName).tag(effect)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Optional notes")
                }
            }
            .navigationTitle("Log Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
                    .disabled(dosageAmount.isEmpty)
                    .accessibilityLabel("Save supplement log")
                    .accessibilityHint(dosageAmount.isEmpty ? "Enter a dosage to enable saving" : "Double tap to save this log entry")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveLog() {
        let log = SupplementLogEntry(
            id: UUID(),
            patientId: UUID(),
            supplementId: preselectedSupplement?.id ?? UUID(),
            routineId: nil,
            supplementName: preselectedSupplement?.name ?? "Supplement",
            dosage: dosageAmount,
            timing: selectedTiming,
            takenAt: Date(),
            skipped: false,
            skipReason: nil,
            perceivedEffect: perceivedEffect,
            sideEffects: nil,
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            supplement: nil
        )
        onSave(log)
        dismiss()
    }
}

#if DEBUG
struct SupplementLogView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementLogView(preselectedSupplement: nil) { _ in }
    }
}
#endif
