//
//  ProgramBuilderView.swift
//  PTPerformance
//

import SwiftUI

struct ProgramBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    let patientId: UUID?

    // Lazy load the view model to avoid blocking during sheet presentation
    @State private var viewModel: ProgramBuilderViewModel?

    init(patientId: UUID? = nil) {
        self.patientId = patientId
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    ProgramBuilderFormView(viewModel: viewModel, patientId: patientId, dismiss: dismiss)
                } else {
                    ProgressView("Loading...")
                        .task {
                            // Create view model asynchronously after view appears
                            await Task.yield() // Let the sheet present first
                            self.viewModel = ProgramBuilderViewModel()
                            await viewModel?.loadProtocols()
                        }
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Form View
struct ProgramBuilderFormView: View {
    @ObservedObject var viewModel: ProgramBuilderViewModel
    let patientId: UUID?
    let dismiss: DismissAction

    // Validation state
    @State private var programNameValidation: ValidationResult?

    // Template library state
    @State private var showTemplateLibrary = false
    @State private var showSaveTemplateSheet = false
    @StateObject private var templateViewModel = ProgramTemplateViewModel()

    var body: some View {
        Form {
            Section("Program Type") {
                Picker("Type", selection: $viewModel.selectedProgramType) {
                    ForEach(ProgramType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Text(viewModel.selectedProgramType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Program Details") {
                // Program name with validation
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Program Name", text: $viewModel.programName)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Program Name")
                        .accessibilityHint("Enter a name for the program between 3 and 100 characters")
                        .onChange(of: viewModel.programName) { _, newValue in
                            programNameValidation = ValidationHelpers.validateProgramName(newValue)
                        }

                    // Show validation error if present
                    if let errorMessage = programNameValidation?.errorMessage, !viewModel.programName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(errorMessage)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(errorMessage)")
                    }
                }

                ProtocolSelector(
                    selectedProtocol: $viewModel.selectedProtocol,
                    protocols: viewModel.filteredProtocols
                )
                .accessibilityLabel("Protocol Selector")
                .accessibilityHint("Choose a therapy protocol for this program")
            }

            Section {
                ForEach(viewModel.phases.indices, id: \.self) { index in
                    if viewModel.phases.indices.contains(index) {
                        NavigationLink {
                            PhaseDetailView(phase: $viewModel.phases[index])
                        } label: {
                            PhaseRowView(
                                phase: viewModel.phases[index],
                                constraints: viewModel.selectedProtocol?.constraints
                            )
                        }
                        .accessibilityLabel("Phase \(index + 1): \(viewModel.phases[index].name)")
                        .accessibilityHint("Edit this phase")
                    }
                }
                .onDelete(perform: viewModel.deletePhase)

                Button(action: viewModel.addPhase) {
                    Label("Add Phase", systemImage: "plus.circle.fill")
                }
                .disabled(!viewModel.canAddPhase)
                .accessibilityLabel("Add Phase")
                .accessibilityHint(viewModel.canAddPhase ? "Add a new phase to the program" : "Maximum phases reached")
            } header: {
                Text("Phases (\(viewModel.phases.count))")
            }

            if let error = viewModel.validationError {
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
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityLabel("Cancel")
                .accessibilityHint("Discard program and return")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Templates button
                    Menu {
                        Button {
                            showTemplateLibrary = true
                        } label: {
                            Label("Browse Templates", systemImage: "doc.on.doc")
                        }

                        if !viewModel.phases.isEmpty {
                            Button {
                                showSaveTemplateSheet = true
                            } label: {
                                Label("Save as Template", systemImage: "square.and.arrow.down")
                            }
                        }
                    } label: {
                        Label("Templates", systemImage: "doc.on.doc")
                    }
                    .accessibilityLabel("Templates")
                    .accessibilityHint("Browse or save program templates")

                    ContextualHelpButton(articleId: nil)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        let logger = DebugLogger.shared
                        logger.log("📝 Creating program: \(viewModel.programName)")
                        do {
                            _ = try await viewModel.createProgram(patientId: patientId?.uuidString)
                            logger.log("✅ Program created successfully", level: .success)
                            dismiss()
                        } catch {
                            logger.log("❌ Failed to create program: \(error.localizedDescription)", level: .error)
                            logger.log("Error details: \(error)", level: .error)
                        }
                    }
                }
                .disabled(!isProgramValid || viewModel.isCreating)
                .accessibilityLabel("Create Program")
                .accessibilityHint(isProgramValid ? "Create the program with current details" : "Complete all required fields to create program")
            }
        }
        .sheet(isPresented: $showTemplateLibrary) {
            ProgramTemplateLibraryView { template in
                // Apply template to current program
                applyTemplate(template)
            }
        }
        .sheet(isPresented: $showSaveTemplateSheet) {
            ProgramSaveTemplateSheet(
                viewModel: templateViewModel,
                programName: viewModel.programName,
                programType: viewModel.selectedProgramType,
                phases: viewModel.phases
            )
        }
    }

    // MARK: - Template Application

    private func applyTemplate(_ template: ProgramTemplate) {
        // Set program type from template
        viewModel.selectedProgramType = template.programType

        // Clear protocol selection since we're using a template
        viewModel.selectedProtocol = nil

        // Convert template phases to program phases
        viewModel.phases = template.phases.map { templatePhase in
            ProgramPhase(
                name: templatePhase.name,
                durationWeeks: templatePhase.durationWeeks,
                sessions: [],
                order: templatePhase.order
            )
        }

        // Suggest a program name based on template
        if viewModel.programName.isEmpty {
            viewModel.programName = template.name.replacingOccurrences(of: " Template", with: "")
        }
    }

    // MARK: - Validation

    private var isProgramValid: Bool {
        // Check program name validation
        let nameValid = programNameValidation?.isValid ?? false

        // Check view model validation
        return nameValid && viewModel.isValid && !viewModel.isCreating
    }
}

struct PhaseRowView: View {
    let phase: ProgramPhase
    let constraints: TherapyProtocol.ProtocolConstraints?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phase.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Text("\(phase.durationWeeks) weeks • \(phase.sessions.count) sessions")
                .font(.caption)
                .foregroundColor(.secondary)

            if let constraints = constraints, !phase.meetsConstraints(constraints) {
                Label("Doesn't meet protocol requirements", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// Supporting model for ProgramPhase
struct ProgramPhase: Identifiable, Hashable {
    let id: UUID
    var name: String
    var durationWeeks: Int
    var sessions: [Session]
    var order: Int

    init(id: UUID = UUID(), name: String, durationWeeks: Int, sessions: [Session] = [], order: Int) {
        self.id = id
        self.name = name
        self.durationWeeks = durationWeeks
        self.sessions = sessions
        self.order = order
    }

    func meetsConstraints(_ constraints: TherapyProtocol.ProtocolConstraints) -> Bool {
        // Basic validation - can be expanded
        return durationWeeks > 0
    }

    struct Session: Identifiable, Hashable {
        let id: UUID
        var name: String
        var exercises: [Exercise]
    }
}
