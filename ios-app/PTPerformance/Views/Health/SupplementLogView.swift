import SwiftUI

/// Supplement Log View - Quick supplement logging
struct SupplementLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SupplementViewModel()

    let preselectedSupplement: Supplement?
    let onSave: (SupplementLogEntry) -> Void

    @State private var selectedTiming: SupplementTiming = .morning
    @State private var dosageAmount: String = ""
    @State private var withFood: Bool = false
    @State private var notes: String = ""

    init(preselectedSupplement: Supplement? = nil, onSave: @escaping (SupplementLogEntry) -> Void) {
        self.preselectedSupplement = preselectedSupplement
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dosage") {
                    TextField("Amount (e.g., 500mg)", text: $dosageAmount)
                        .keyboardType(.decimalPad)
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

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
                }
            }
        }
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
            perceivedEffect: nil,
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
