//
//  BodyCompositionEntryView.swift
//  PTPerformance
//
//  Sheet form for adding body composition entries (ACP-510)
//

import SwiftUI

/// Sheet form for adding a new body composition entry
struct BodyCompositionEntryView: View {
    @StateObject private var viewModel = BodyCompositionViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var didSave: Bool

    /// The patient ID to save the entry for
    let patientId: String

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Weight & Body Fat Section
                Section(header: Text("Weight & Body Fat")) {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lbs", text: $viewModel.weightLb)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Body Fat")
                        Spacer()
                        TextField("%", text: $viewModel.bodyFatPercent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Muscle Mass")
                        Spacer()
                        TextField("lbs", text: $viewModel.muscleMassLb)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                // MARK: - Measurements Section
                Section(header: Text("Measurements (inches)")) {
                    HStack {
                        Text("Waist")
                        Spacer()
                        TextField("in", text: $viewModel.waistIn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Chest")
                        Spacer()
                        TextField("in", text: $viewModel.chestIn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Arms")
                        Spacer()
                        TextField("in", text: $viewModel.armIn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Legs")
                        Spacer()
                        TextField("in", text: $viewModel.legIn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                // MARK: - Notes Section
                Section(header: Text("Notes")) {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveEntry()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasValidInput)
                }
            }
            .alert("Entry Saved", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    didSave = true
                    dismiss()
                }
            } message: {
                Text("Your body composition entry has been saved.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    // MARK: - Actions

    private func saveEntry() {
        Task {
            await viewModel.saveEntry(patientId: patientId)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BodyCompositionEntryView_Previews: PreviewProvider {
    static var previews: some View {
        BodyCompositionEntryView(
            didSave: .constant(false),
            patientId: UUID().uuidString
        )
    }
}
#endif
