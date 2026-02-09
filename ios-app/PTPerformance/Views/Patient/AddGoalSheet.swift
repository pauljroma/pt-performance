//
//  AddGoalSheet.swift
//  PTPerformance
//
//  ACP-523: Patient Profile Goals & Progress
//

import SwiftUI

/// Sheet view for creating a new patient goal
struct AddGoalSheet: View {
    @ObservedObject var viewModel: PatientGoalsViewModel
    @Environment(\.dismiss) private var dismiss

    /// Resolved patient UUID from PTSupabaseClient.shared.userId
    private var patientUUID: UUID? {
        guard let idString = PTSupabaseClient.shared.userId else { return nil }
        return UUID(uuidString: idString)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Title Section
                Section {
                    TextField("Goal title", text: $viewModel.title)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Required. Give your goal a clear, specific name.")
                }

                // MARK: - Description Section
                Section {
                    TextEditor(text: $viewModel.goalDescription)
                        .frame(minHeight: 80)
                        .overlay(
                            Group {
                                if viewModel.goalDescription.isEmpty {
                                    Text("Describe your goal in detail...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                } header: {
                    Text("Description")
                }

                // MARK: - Category Section
                Section {
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(GoalCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Category")
                }

                // MARK: - Target & Measurement Section
                Section {
                    HStack {
                        Text("Target Value")
                        Spacer()
                        TextField("e.g. 100", text: $viewModel.targetValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Unit")
                        Spacer()
                        TextField("e.g. lbs, reps, mins", text: $viewModel.unit)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }

                    HStack {
                        Text("Starting Value")
                        Spacer()
                        TextField("e.g. 50", text: $viewModel.currentValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Measurement")
                } footer: {
                    Text("Optional. Set a numeric target and unit to track measurable progress.")
                }

                // MARK: - Target Date Section
                Section {
                    Toggle("Set Target Date", isOn: $viewModel.hasTargetDate)

                    if viewModel.hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: $viewModel.targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Timeline")
                }

                // MARK: - Error Message (BUILD 314: Updated to use AppError)
                if let error = viewModel.error {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            guard let uuid = patientUUID else {
                                viewModel.error = .notAuthenticated
                                return
                            }
                            await viewModel.saveGoal(patientId: uuid)
                            if viewModel.showingSuccessAlert {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

struct AddGoalSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddGoalSheet(viewModel: PatientGoalsViewModel())
    }
}
