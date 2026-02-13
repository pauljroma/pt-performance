//
//  PhaseDetailView.swift
//  PTPerformance
//
//  Build 50: Detail view for managing sessions within a phase
//

import SwiftUI

struct PhaseDetailView: View {
    @Binding var phase: ProgramPhase
    @State private var editingSession: ProgramPhase.Session?
    @State private var showSessionBuilder = false
    @State private var editingSessionIndex: Int?

    var body: some View {
        Form {
            Section("Phase Details") {
                TextField("Phase Name", text: $phase.name)
                    .textInputAutocapitalization(.words)

                Stepper("Duration: \(phase.durationWeeks) \(phase.durationWeeks == 1 ? "week" : "weeks")",
                        value: $phase.durationWeeks,
                        in: 1...52)
            }

            Section {
                if phase.sessions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No sessions added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Add Session' to create your first session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(phase.sessions.indices, id: \.self) { index in
                        Button {
                            editSession(at: index)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(phase.sessions[index].name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("\(phase.sessions[index].exercises.count) \(phase.sessions[index].exercises.count == 1 ? "exercise" : "exercises")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteSession)
                }

                Button {
                    addSession()
                } label: {
                    Label("Add Session", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Sessions (\(phase.sessions.count))")
            }
        }
        .navigationTitle("Edit Phase")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSessionBuilder) {
            if let index = editingSessionIndex,
               phase.sessions.indices.contains(index) {
                SessionBuilderSheet(
                    session: $phase.sessions[index],
                    isPresented: $showSessionBuilder
                )
            }
        }
    }

    private func addSession() {
        let newSession = ProgramPhase.Session(
            id: UUID(),
            name: "Session \(phase.sessions.count + 1)",
            exercises: []
        )
        phase.sessions.append(newSession)
        editingSessionIndex = phase.sessions.count - 1
        showSessionBuilder = true
    }

    private func editSession(at index: Int) {
        editingSessionIndex = index
        showSessionBuilder = true
    }

    private func deleteSession(at offsets: IndexSet) {
        // Clear stale index to prevent $phase.sessions[index] out-of-bounds crash
        if let index = editingSessionIndex, offsets.contains(index) {
            editingSessionIndex = nil
            showSessionBuilder = false
        }
        phase.sessions.remove(atOffsets: offsets)
    }
}

#Preview {
    NavigationStack {
        PhaseDetailView(
            phase: .constant(
                ProgramPhase(
                    id: UUID(),
                    name: "Foundation Phase",
                    durationWeeks: 4,
                    sessions: [
                        ProgramPhase.Session(
                            id: UUID(),
                            name: "Day 1: Upper Body",
                            exercises: Exercise.sampleExercises
                        ),
                        ProgramPhase.Session(
                            id: UUID(),
                            name: "Day 2: Lower Body",
                            exercises: []
                        )
                    ],
                    order: 1
                )
            )
        )
    }
}
