//
//  ProgramStructureView.swift
//  PTPerformance
//
//  Build 50: Navigate program hierarchy (Phases → Sessions → Exercises)
//

import SwiftUI

struct ProgramStructureView: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    let program: Program
    @State private var phases: [Phase] = []
    @State private var sessionsByPhase: [String: [Session]] = [:]
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading program structure...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = error {
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
                            await loadProgramStructure()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if phases.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No phases found in this program")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(phases) { phase in
                        Section(header: Text(phase.name)) {
                            PhaseSessionsView(
                                phase: phase,
                                sessions: sessionsByPhase[phase.id] ?? [],
                                viewModel: viewModel
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    if let patientId = UUID(uuidString: program.patientId) {
                        ProgramEditorView(programId: program.id, patientId: patientId)
                    }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .task {
            await loadProgramStructure()
        }
    }

    private func loadProgramStructure() async {
        let logger = DebugLogger.shared
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            logger.log("📋 Loading phases for program: \(program.name)")

            // Load phases for this program
            let decoder = JSONDecoder()
            // NOTE: Phase model has explicit CodingKeys, do NOT use .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let result = try await PTSupabaseClient.shared.client
                .from("phases")
                .select()
                .eq("program_id", value: program.id)
                .order("phase_number")
                .execute()

            logger.log("   Response size: \(result.data.count) bytes")
            phases = try decoder.decode([Phase].self, from: result.data)
            logger.log("✅ Loaded \(phases.count) phases", level: .success)

            // Batch-load all sessions for all phases in ONE query (prevents flickering)
            if !phases.isEmpty {
                logger.log("📅 Batch-loading sessions for all phases...")

                let sessionDecoder = JSONDecoder()
                // NOTE: Session model uses snake_case properties, do NOT use .convertFromSnakeCase
                sessionDecoder.dateDecodingStrategy = .iso8601

                // Load all sessions where phase_id matches any of our phase IDs
                let phaseIds = phases.map { $0.id }
                let sessionResult = try await PTSupabaseClient.shared.client
                    .from("sessions")
                    .select()
                    .in("phase_id", values: phaseIds)
                    .order("sequence")
                    .execute()

                let allSessions = try sessionDecoder.decode([Session].self, from: sessionResult.data)
                logger.log("✅ Batch-loaded \(allSessions.count) total sessions", level: .success)

                // Group sessions by phase_id
                sessionsByPhase = Dictionary(grouping: allSessions, by: { $0.phase_id })
                logger.log("   Distributed to \(sessionsByPhase.keys.count) phases")
            }
        } catch {
            self.error = "Failed to load program structure: \(error.localizedDescription)"
            logger.log("❌ Failed to load phases: \(error.localizedDescription)", level: .error)
            logger.log("Error details: \(error)", level: .error)
        }
    }
}

struct PhaseSessionsView: View {
    let phase: Phase
    let sessions: [Session]
    @ObservedObject var viewModel: ProgramEditorViewModel

    var body: some View {
        Group {
            if sessions.isEmpty {
                Text("No sessions in this phase")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionEditorDetailView(
                            viewModel: viewModel,
                            session: session,
                            phaseName: phase.name
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.name)
                                    .font(.subheadline)

                                if let weekday = session.weekday {
                                    Text("Day \(weekday)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProgramStructureView(
            viewModel: ProgramEditorViewModel(
                patientId: UUID(),
                exerciseId: nil
            ),
            program: Program(
                id: UUID().uuidString,
                patientId: UUID().uuidString,
                name: "8-Week On-Ramp",
                targetLevel: "intermediate",
                durationWeeks: 8,
                createdAt: Date(),
                status: "active"
            )
        )
    }
}
