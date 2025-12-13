//
//  ProgramBuilderView.swift
//  PTPerformance
//

import SwiftUI

struct ProgramBuilderView: View {
    @StateObject private var viewModel = ProgramBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    let patientId: UUID?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Program Details") {
                    TextField("Program Name", text: $viewModel.programName)
                        .textInputAutocapitalization(.words)
                    
                    ProtocolSelector(
                        selectedProtocol: $viewModel.selectedProtocol,
                        protocols: viewModel.availableProtocols
                    )
                }
                
                Section {
                    ForEach(viewModel.phases) { phase in
                        PhaseRowView(
                            phase: phase,
                            constraints: viewModel.selectedProtocol?.constraints
                        )
                    }
                    .onDelete(perform: viewModel.deletePhase)
                    
                    Button(action: viewModel.addPhase) {
                        Label("Add Phase", systemImage: "plus.circle.fill")
                    }
                    .disabled(!viewModel.canAddPhase)
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
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            do {
                                _ = try await viewModel.createProgram(patientId: patientId?.uuidString)
                                dismiss()
                            } catch {
                                // Error already logged by viewModel
                                print("Failed to create program: \(error)")
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isCreating)
                }
            }
            .task {
                await viewModel.loadProtocols()
            }
        }
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
