//
//  PrescribeWorkoutSheet.swift
//  PTPerformance
//
//  Sheet for therapists to prescribe workouts to patients
//

import SwiftUI

/// Sheet for prescribing a workout to a patient
struct PrescribeWorkoutSheet: View {
    let patient: Patient
    let therapistId: String
    let onDismiss: () -> Void

    @StateObject private var viewModel = PrescribeWorkoutViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSuccess {
                    successView
                } else {
                    prescriptionForm
                }
            }
            .navigationTitle("Prescribe Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticFeedback.light()
                        dismiss()
                        onDismiss()
                    }
                }

                if !viewModel.isSuccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Prescribe") {
                            Task {
                                await prescribe()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
            .task {
                await viewModel.loadTemplates()
            }
        }
    }

    // MARK: - Prescription Form

    private var prescriptionForm: some View {
        List {
            // Patient info section
            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(patient.initials)
                                .font(.headline)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(patient.fullName)
                            .font(.headline)

                        if let sport = patient.sport, let position = patient.position {
                            Text("\(sport) - \(position)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if let sport = patient.sport {
                            Text(sport)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Patient")
            }

            // Template selection section
            Section {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading templates...")
                        Spacer()
                    }
                    .padding(.vertical, 24)
                } else if viewModel.filteredTemplates.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        if viewModel.searchText.isEmpty {
                            Text("No Templates Available")
                                .font(.headline)
                            Text("System templates will appear here once configured.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("No Matching Templates")
                                .font(.headline)
                            Text("Try adjusting your search terms.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search templates...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    ForEach(viewModel.filteredTemplates) { template in
                        PrescriptionTemplateRow(
                            template: template,
                            isSelected: viewModel.selectedTemplate?.id == template.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.selectedTemplate = template
                                }
                                HapticFeedback.selectionChanged()
                            }
                        )
                    }
                }
            } header: {
                Text("Select Workout Template")
            }

            // Due date section
            Section {
                DatePicker(
                    "Due Date",
                    selection: $viewModel.dueDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            } header: {
                Text("Due Date")
            } footer: {
                Text("The patient will see this workout in their assigned workouts until completed or past due.")
            }

            // Priority section
            Section {
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(PrescriptionPriority.allCases, id: \.self) { priority in
                        HStack {
                            Circle()
                                .fill(priorityColor(priority))
                                .frame(width: 10, height: 10)
                            Text(priority.displayName)
                        }
                        .tag(priority)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Priority")
            } footer: {
                Text(priorityDescription(viewModel.priority))
            }

            // Instructions section
            Section {
                TextEditor(text: $viewModel.instructions)
                    .frame(minHeight: 100)
            } header: {
                Text("Custom Instructions (Optional)")
            } footer: {
                Text("Add any specific instructions or notes for the patient about this workout.")
            }

            // Error message
            if let error = viewModel.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Loading indicator
            if viewModel.isSubmitting {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Prescribing workout...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Workout Prescribed")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                Text("\(viewModel.selectedTemplate?.name ?? "Workout") has been assigned to \(patient.firstName).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("Due: \(viewModel.dueDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: {
                HapticFeedback.medium()
                dismiss()
                onDismiss()
            }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helper Views & Functions

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func priorityColor(_ priority: PrescriptionPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    private func priorityDescription(_ priority: PrescriptionPriority) -> String {
        switch priority {
        case .low:
            return "Low priority - Patient can complete when convenient."
        case .medium:
            return "Medium priority - Standard workout assignment."
        case .high:
            return "High priority - Important for recovery progress."
        case .urgent:
            return "Urgent - Patient should complete as soon as possible."
        }
    }

    private func prescribe() async {
        guard let therapistUUID = UUID(uuidString: therapistId) else {
            viewModel.errorMessage = "Invalid therapist ID."
            return
        }

        HapticFeedback.medium()

        let success = await viewModel.createPrescription(
            patientId: patient.id,
            therapistId: therapistUUID
        )

        if success {
            HapticFeedback.success()
        } else {
            HapticFeedback.error()
        }
    }
}

// MARK: - Prescription Template Row

private struct PrescriptionTemplateRow: View {
    let template: SystemWorkoutTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let category = template.category {
                            Label(category.capitalized, systemImage: "tag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let duration = template.durationDisplay {
                            Label(duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if template.exerciseCount > 0 {
                            Label("\(template.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let description = template.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name), \(template.durationDisplay ?? ""), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this template")
    }
}

// MARK: - Preview

#if DEBUG
struct PrescribeWorkoutSheet_Previews: PreviewProvider {
    static var previews: some View {
        PrescribeWorkoutSheet(
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "John",
                lastName: "Brebbia",
                email: "john@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Elbow UCL",
                targetLevel: "MLB",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 85.0,
                lastSessionDate: Date()
            ),
            therapistId: UUID().uuidString,
            onDismiss: {}
        )
    }
}
#endif
