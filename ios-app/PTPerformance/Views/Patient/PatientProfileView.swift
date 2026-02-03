import SwiftUI

/// Patient Profile View
/// Allows patients to view and edit their demographic and medical history information
/// BUILD 96 - Patient Profile Feature (Minimal)
struct PatientProfileView: View {
    @StateObject private var viewModel = PatientProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    let patientId: String

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Form {
                        // MARK: - Demographics Section
                        Section(header: Text("Demographics")) {
                            // Age (read-only, calculated from date of birth)
                            HStack {
                                Text("Age")
                                Spacer()
                                Text(viewModel.age.isEmpty ? "Not set" : viewModel.age)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Age: \(viewModel.age.isEmpty ? "Not set" : viewModel.age)")

                            // Gender
                            Picker("Gender", selection: $viewModel.gender) {
                                ForEach(viewModel.genderOptions, id: \.self) { option in
                                    Text(option.isEmpty ? "Not specified" : option).tag(option)
                                }
                            }
                            .accessibilityLabel("Gender")
                            .accessibilityValue(viewModel.gender.isEmpty ? "Not specified" : viewModel.gender)

                            // Height
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Height (inches)")
                                    Spacer()
                                    TextField("", text: $viewModel.heightInches)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                        .accessibilityLabel("Height in inches")
                                        .accessibilityValue(viewModel.heightInches.isEmpty ? "Not set" : "\(viewModel.heightInches) inches")
                                }

                                if let error = viewModel.heightError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .accessibilityLabel("Height error: \(error)")
                                }
                            }

                            // Weight
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Weight (lbs)")
                                    Spacer()
                                    TextField("", text: $viewModel.weightLbs)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                        .accessibilityLabel("Weight in pounds")
                                        .accessibilityValue(viewModel.weightLbs.isEmpty ? "Not set" : "\(viewModel.weightLbs) pounds")
                                }

                                if let error = viewModel.weightError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .accessibilityLabel("Weight error: \(error)")
                                }
                            }
                        }

                        // MARK: - Medical History Section
                        Section(header: Text("Medical History")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Injury History")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextEditor(text: $viewModel.injuryHistory)
                                    .frame(minHeight: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Injury History")
                                    .accessibilityHint("Enter each injury on a new line")
                                Text("Enter each injury on a new line (e.g., \"2025: Grade 1 tricep strain (elbow)\")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Surgery History")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextEditor(text: $viewModel.surgeryHistory)
                                    .frame(minHeight: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Surgery History")
                                    .accessibilityHint("Enter each surgery on a new line")
                                Text("Enter each surgery on a new line (e.g., \"2023: Tommy John Surgery\")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Allergies")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Enter allergies separated by commas", text: $viewModel.allergies)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .accessibilityLabel("Allergies")
                                    .accessibilityHint("Enter allergies separated by commas")
                                Text("Example: penicillin, peanuts, latex")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // MARK: - Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .accessibilityHidden(true)
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Error: \(errorMessage)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Closes without saving changes")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveProfile()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .accessibilityHidden(true)
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.isLoading)
                    .accessibilityLabel(viewModel.isSaving ? "Saving profile" : "Save")
                    .accessibilityHint("Saves your profile changes")
                }
            }
            .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    viewModel.clearSuccessMessage()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "Profile updated successfully")
            }
            .task {
                await viewModel.loadProfile(patientId: patientId)
            }
        }
    }
}

// MARK: - Preview

struct PatientProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PatientProfileView(patientId: "00000000-0000-0000-0000-000000000001")
    }
}
