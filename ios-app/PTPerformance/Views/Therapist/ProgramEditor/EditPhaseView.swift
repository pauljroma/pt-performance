//
//  EditPhaseView.swift
//  PTPerformance
//
//  Build 60: Edit phase details and manage sessions (ACP-114)
//

import SwiftUI

struct EditPhaseView: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    let phaseIndex: Int
    @State private var sessions: [Session] = []
    @State private var isLoadingSessions = false
    @State private var sessionsError: String?
    @State private var showAddSession = false
    @State private var newSessionName = ""

    private var phase: Binding<Phase> {
        Binding(
            get: { viewModel.phases[phaseIndex] },
            set: { viewModel.phases[phaseIndex] = $0 }
        )
    }

    var body: some View {
        Form {
            Section("Phase Details") {
                TextField("Phase Name", text: Binding(
                    get: { phase.wrappedValue.name },
                    set: { newValue in
                        phase.wrappedValue = Phase(
                            id: phase.wrappedValue.id,
                            programId: phase.wrappedValue.programId,
                            phaseNumber: phase.wrappedValue.phaseNumber,
                            name: newValue,
                            durationWeeks: phase.wrappedValue.durationWeeks,
                            goals: phase.wrappedValue.goals
                        )
                    }
                ))
                .textInputAutocapitalization(.words)

                Stepper(
                    "Duration: \(phase.wrappedValue.durationWeeks ?? 1) \(phase.wrappedValue.durationWeeks == 1 ? "week" : "weeks")",
                    value: Binding(
                        get: { phase.wrappedValue.durationWeeks ?? 1 },
                        set: { newValue in
                            phase.wrappedValue = Phase(
                                id: phase.wrappedValue.id,
                                programId: phase.wrappedValue.programId,
                                phaseNumber: phase.wrappedValue.phaseNumber,
                                name: phase.wrappedValue.name,
                                durationWeeks: newValue,
                                goals: phase.wrappedValue.goals
                            )
                        }
                    ),
                    in: 1...52
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: Binding(
                        get: { phase.wrappedValue.goals ?? "" },
                        set: { newValue in
                            phase.wrappedValue = Phase(
                                id: phase.wrappedValue.id,
                                programId: phase.wrappedValue.programId,
                                phaseNumber: phase.wrappedValue.phaseNumber,
                                name: phase.wrappedValue.name,
                                durationWeeks: phase.wrappedValue.durationWeeks,
                                goals: newValue.isEmpty ? nil : newValue
                            )
                        }
                    ))
                    .frame(minHeight: 80)
                }
            }

            Section {
                if isLoadingSessions {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading sessions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.sm)
                        Spacer()
                    }
                } else if let error = sessionsError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadSessions()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, Spacing.sm)
                } else if sessions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No sessions in this phase")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Add Session' to create your first session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, Spacing.lg)
                        Spacer()
                    }
                } else {
                    ForEach(sessions.sorted(by: { $0.sequence < $1.sequence })) { session in
                        NavigationLink {
                            EditSessionView(
                                viewModel: viewModel,
                                session: session,
                                phaseName: phase.wrappedValue.name
                            )
                        } label: {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete(perform: deleteSession)
                }

                Button {
                    showAddSession = true
                } label: {
                    Label("Add Session", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Sessions (\(sessions.count))")
            }
        }
        .navigationTitle("Edit Phase")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSessions()
        }
        .alert("Add Session", isPresented: $showAddSession) {
            TextField("Session Name", text: $newSessionName)
            Button("Cancel", role: .cancel) {
                newSessionName = ""
            }
            Button("Add") {
                Task {
                    await addSession()
                }
            }
            .disabled(newSessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a name for the new session")
        }
    }

    private func loadSessions() async {
        let logger = DebugLogger.shared
        isLoadingSessions = true
        sessionsError = nil
        defer { isLoadingSessions = false }

        do {
            logger.log("📅 Loading sessions for phase: \(phase.wrappedValue.name)")

            let decoder = PTSupabaseClient.flexibleDecoder

            let result = try await PTSupabaseClient.shared.client
                .from("sessions")
                .select()
                .eq("phase_id", value: phase.wrappedValue.id)
                .order("sequence")
                .execute()

            sessions = try decoder.decode([Session].self, from: result.data)
            logger.log("✅ Loaded \(sessions.count) sessions", level: .success)
        } catch {
            sessionsError = "Failed to load sessions: \(error.localizedDescription)"
            logger.log("❌ Failed to load sessions: \(error)", level: .error)
        }
    }

    private func addSession() async {
        let logger = DebugLogger.shared
        let sessionName = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessionName.isEmpty else { return }

        do {
            logger.log("➕ Creating new session: \(sessionName)")

            let newSequence = (sessions.map { $0.sequence }.max() ?? 0) + 1

            let sessionInput = CreateSessionInput(
                phaseId: phase.wrappedValue.id.uuidString,
                name: sessionName,
                sequence: newSequence,
                weekday: nil,
                notes: nil
            )

            let decoder = PTSupabaseClient.flexibleDecoder

            let result = try await PTSupabaseClient.shared.client
                .from("sessions")
                .insert(sessionInput)
                .select()
                .single()
                .execute()

            let newSession = try decoder.decode(Session.self, from: result.data)
            sessions.append(newSession)
            newSessionName = ""

            logger.log("✅ Session created successfully", level: .success)
        } catch {
            logger.log("❌ Failed to create session: \(error)", level: .error)
            sessionsError = "Failed to create session: \(error.localizedDescription)"
        }
    }

    private func deleteSession(at offsets: IndexSet) {
        let logger = DebugLogger.shared

        for index in offsets {
            let session = sessions[index]
            logger.log("🗑️ Deleting session: \(session.name)")

            Task {
                do {
                    try await PTSupabaseClient.shared.client
                        .from("sessions")
                        .delete()
                        .eq("id", value: session.id)
                        .execute()

                    logger.log("✅ Session deleted successfully", level: .success)

                    // Remove from local array
                    _ = await MainActor.run {
                        sessions.remove(at: index)
                    }
                } catch {
                    logger.log("❌ Failed to delete session: \(error)", level: .error)
                    await MainActor.run {
                        sessionsError = "Failed to delete session: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.name)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                if let weekday = session.weekday {
                    Text("Day \(weekday)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if session.completed == true {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// CreateSessionInput is defined in ProgramBuilderViewModel.swift and shared across the app

#Preview {
    NavigationStack {
        EditPhaseView(
            viewModel: ProgramEditorViewModel(
                patientId: UUID(),
                exerciseId: nil
            ),
            phaseIndex: 0
        )
    }
}
