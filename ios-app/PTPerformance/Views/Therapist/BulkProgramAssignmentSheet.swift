//
//  BulkProgramAssignmentSheet.swift
//  PTPerformance
//
//  Bulk program assignment sheet for assigning programs to multiple patients
//

import SwiftUI

/// Sheet for assigning a program to multiple selected patients
struct BulkProgramAssignmentSheet: View {
    @ObservedObject var viewModel: PatientListViewModel
    let therapistId: String
    let onDismiss: () -> Void

    @State private var selectedProgramId: UUID?
    @State private var showingConfirmation = false
    @State private var assignmentComplete = false
    @State private var assignmentMessage = ""

    @Environment(\.dismiss) private var dismiss

    private var selectedPatients: [Patient] {
        viewModel.selectedPatients
    }

    var body: some View {
        NavigationStack {
            Group {
                if assignmentComplete {
                    completionView
                } else {
                    assignmentForm
                }
            }
            .navigationTitle("Assign Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticFeedback.light()
                        dismiss()
                        onDismiss()
                    }
                }

                if !assignmentComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Assign") {
                            showingConfirmation = true
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedProgramId == nil || viewModel.isBulkOperationInProgress)
                    }
                }
            }
            .task {
                await viewModel.loadAvailablePrograms(therapistId: therapistId)
            }
            .confirmationDialog(
                "Assign Program",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Assign to \(selectedPatients.count) Patients") {
                    Task {
                        await performAssignment()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will create a new program for each selected patient based on the chosen template.")
            }
        }
    }

    // MARK: - Assignment Form

    private var assignmentForm: some View {
        List {
            // Selected patients section
            Section {
                ForEach(selectedPatients) { patient in
                    HStack(spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(avatarColor(for: patient))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(patient.initials)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(patient.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if let sport = patient.sport {
                                Text(sport)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(patient.fullName), \(patient.sport ?? "no sport")")
                }
            } header: {
                Text("Selected Patients (\(selectedPatients.count))")
            }

            // Program selection section
            Section {
                if viewModel.availablePrograms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("No Program Templates")
                            .font(.headline)

                        Text("Create program templates first to use bulk assignment.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(viewModel.availablePrograms) { program in
                        DatabaseProgramTemplateRow(
                            program: program,
                            isSelected: selectedProgramId == program.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedProgramId = program.id
                                }
                                HapticFeedback.selectionChanged()
                            }
                        )
                    }
                }
            } header: {
                Text("Select Program Template")
            } footer: {
                if !viewModel.availablePrograms.isEmpty {
                    Text("The selected program template will be assigned to all \(selectedPatients.count) patients.")
                }
            }

            // Loading indicator
            if viewModel.isBulkOperationInProgress {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Assigning programs...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            // Error message
            if let error = viewModel.bulkOperationError {
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
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Programs Assigned")
                .font(.title2)
                .fontWeight(.semibold)

            Text(assignmentMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: {
                HapticFeedback.medium()
                viewModel.clearSelectionAndExit()
                dismiss()
                onDismiss()
            }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helper Functions

    private func avatarColor(for patient: Patient) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo]
        let index = abs(patient.id.hashValue) % colors.count
        return colors[index]
    }

    private func performAssignment() async {
        guard let programId = selectedProgramId else { return }

        HapticFeedback.medium()

        let success = await viewModel.bulkAssignProgram(
            programTemplateId: programId,
            patientIds: viewModel.selectedPatientIds,
            therapistId: therapistId
        )

        if success {
            HapticFeedback.success()
            assignmentMessage = "Successfully assigned the program to \(selectedPatients.count) patients."
            withAnimation(.easeInOut(duration: 0.3)) {
                assignmentComplete = true
            }
        } else {
            HapticFeedback.error()
        }
    }
}

// MARK: - Program Template Row

/// Row displaying a database program template for selection
struct DatabaseProgramTemplateRow: View {
    let program: DatabaseProgramTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                // Program info
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let type = program.programType {
                            Label(type.displayName, systemImage: type.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("\(program.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let description = program.description, !description.isEmpty {
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
        .accessibilityLabel("\(program.name), \(program.durationWeeks) weeks, \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this program")
    }
}

// MARK: - Preview

#if DEBUG
struct BulkProgramAssignmentSheet_Previews: PreviewProvider {
    static var previews: some View {
        BulkProgramAssignmentSheet(
            viewModel: PatientListViewModel(),
            therapistId: "therapist-1",
            onDismiss: {}
        )
    }
}
#endif
