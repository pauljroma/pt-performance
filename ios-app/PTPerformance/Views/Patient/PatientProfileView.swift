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

                            // Gender
                            Picker("Gender", selection: $viewModel.gender) {
                                ForEach(viewModel.genderOptions, id: \.self) { option in
                                    Text(option.isEmpty ? "Not specified" : option).tag(option)
                                }
                            }

                            // Height
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Height (inches)")
                                    Spacer()
                                    TextField("", text: $viewModel.heightInches)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                }

                                if let error = viewModel.heightError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
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
                                }

                                if let error = viewModel.weightError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
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
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                }
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
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.isLoading)
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
