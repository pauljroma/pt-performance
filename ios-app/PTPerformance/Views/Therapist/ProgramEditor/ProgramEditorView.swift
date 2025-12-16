//
//  ProgramEditorView.swift
//  PTPerformance
//
//  Build 60: Full CRUD operations for editing existing programs (ACP-114)
//

import SwiftUI

struct ProgramEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProgramEditorViewModel
    let programId: String

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var selectedPhaseIndex: Int?

    init(programId: String, patientId: UUID) {
        self.programId = programId
        self._viewModel = StateObject(wrappedValue: ProgramEditorViewModel(patientId: patientId, exerciseId: nil))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading program...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadProgram(programId: programId)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    programEditorForm
                }
            }
            .navigationTitle("Edit Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.saveProgram()
                                dismiss()
                            } catch {
                                // Error is already set in viewModel
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || !isValid)
                }
            }
            .task {
                await viewModel.loadProgram(programId: programId)
            }
            .alert("Delete Program?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteProgram()
                    }
                }
            } message: {
                Text("This will permanently delete the program and all associated phases, sessions, and exercises. This action cannot be undone.")
            }
        }
    }

    private var programEditorForm: some View {
        Form {
            Section("Program Details") {
                TextField("Program Name", text: $viewModel.programName)
                    .textInputAutocapitalization(.words)

                Picker("Target Level", selection: $viewModel.targetLevel) {
                    Text("Beginner").tag("Beginner")
                    Text("Intermediate").tag("Intermediate")
                    Text("Advanced").tag("Advanced")
                }

                Stepper("Duration: \(viewModel.durationWeeks) \(viewModel.durationWeeks == 1 ? "week" : "weeks")",
                        value: $viewModel.durationWeeks,
                        in: 1...104)
            }

            Section {
                if viewModel.phases.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No phases in this program")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Add Phase' to create your first phase")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.phases.indices, id: \.self) { index in
                        NavigationLink {
                            EditPhaseView(
                                viewModel: viewModel,
                                phaseIndex: index
                            )
                        } label: {
                            EditorPhaseRowView(phase: viewModel.phases[index])
                        }
                    }
                    .onDelete(perform: deletePhase)
                }

                Button(action: addPhase) {
                    Label("Add Phase", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Phases (\(viewModel.phases.count))")
            }

            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            if let error = viewModel.error {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Label("Delete Program", systemImage: "trash")
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting)
            }
        }
    }

    private var isValid: Bool {
        !viewModel.programName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.programName.count >= 3 &&
        viewModel.programName.count <= 100 &&
        viewModel.durationWeeks > 0 &&
        !viewModel.phases.isEmpty
    }

    private func addPhase() {
        // Create a new phase and add it to the phases array
        // Note: This creates an in-memory phase that will be saved when user taps Save
        let newPhaseNumber = viewModel.phases.count + 1
        let newPhase = Phase(
            id: UUID().uuidString,
            programId: programId,
            phaseNumber: newPhaseNumber,
            name: "Phase \(newPhaseNumber)",
            durationWeeks: 2,
            goals: nil
        )
        viewModel.phases.append(newPhase)
    }

    private func deletePhase(at offsets: IndexSet) {
        viewModel.phases.remove(atOffsets: offsets)

        // Reorder remaining phases
        for (index, _) in viewModel.phases.enumerated() {
            viewModel.phases[index] = Phase(
                id: viewModel.phases[index].id,
                programId: viewModel.phases[index].programId,
                phaseNumber: index + 1,
                name: viewModel.phases[index].name,
                durationWeeks: viewModel.phases[index].durationWeeks,
                goals: viewModel.phases[index].goals
            )
        }
    }

    private func deleteProgram() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await viewModel.deleteProgram(programId: programId)
            dismiss()
        } catch {
            // Error is already set in viewModel
        }
    }
}

/// Phase row view for program editor (renamed to avoid conflict with ProgramBuilderView's PhaseRowView)
struct EditorPhaseRowView: View {
    let phase: Phase

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phase.name)
                .font(.subheadline)
                .fontWeight(.medium)

            if let weeks = phase.durationWeeks {
                Text("\(weeks) weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let goals = phase.goals, !goals.isEmpty {
                Text(goals)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        ProgramEditorView(
            programId: UUID().uuidString,
            patientId: UUID()
        )
    }
}
