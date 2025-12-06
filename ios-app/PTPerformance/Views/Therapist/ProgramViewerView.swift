import SwiftUI

/// Program viewer showing phases → sessions → exercises
struct ProgramViewerView: View {
    let patientId: String

    @StateObject private var viewModel = ProgramViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading program...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.fetchProgram(for: patientId)
                    }
                }
            } else {
                programContent
            }
        }
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.fetchProgram(for: patientId)
        }
    }

    private var programContent: some View {
        List {
            // Program header
            if let program = viewModel.program {
                Section {
                    ProgramHeaderView(program: program)
                }
            }

            // Phases
            ForEach(viewModel.phases) { phase in
                Section {
                    PhaseView(
                        phase: phase,
                        sessions: viewModel.sessions(for: phase),
                        exercisesBySession: viewModel.exercisesBySession
                    )
                } header: {
                    HStack {
                        Text("Phase \(phase.phaseNumber): \(phase.name)")
                        Spacer()
                        Text("\(phase.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Program Header

struct ProgramHeaderView: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(program.name)
                .font(.title2)
                .bold()

            HStack {
                Label("Target: \(program.targetLevel)", systemImage: "target")
                Spacer()
                Label("\(program.durationWeeks) weeks", systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Phase View

struct PhaseView: View {
    let phase: Phase
    let sessions: [ProgramSession]
    let exercisesBySession: [String: [ProgramExercise]]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let goals = phase.goals {
                Text(goals)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            // Sessions
            ForEach(sessions) { session in
                SessionDisclosureView(
                    session: session,
                    exercises: exercisesBySession[session.id] ?? []
                )
            }
        }
    }
}

// MARK: - Session Disclosure View

struct SessionDisclosureView: View {
    let session: ProgramSession
    let exercises: [ProgramExercise]

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if exercises.isEmpty {
                Text("No exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises) { exercise in
                        ExerciseRowCompact(exercise: exercise)
                    }
                }
                .padding(.top, 8)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session \(session.sessionNumber)")
                        .font(.subheadline)
                        .bold()

                    if let date = session.sessionDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let exerciseCount = session.exerciseCount {
                    Text("\(exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if session.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Row Compact

struct ExerciseRowCompact: View {
    let exercise: ProgramExercise

    var body: some View {
        HStack {
            // Order badge
            Text("\(exercise.orderIndex + 1)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))

            // Exercise name
            Text(exercise.exerciseName)
                .font(.subheadline)

            Spacer()

            // Prescription
            HStack(spacing: 16) {
                Label("\(exercise.sets)", systemImage: "number")
                    .font(.caption)

                Label("\(exercise.reps)", systemImage: "repeat")
                    .font(.caption)

                if let load = exercise.load {
                    Label("\(Int(load)) \(exercise.loadUnit ?? "lbs")", systemImage: "scalemass")
                        .font(.caption)
                }

                if let rest = exercise.restPeriod {
                    Label("\(rest)s", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ProgramViewerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProgramViewerView(patientId: "patient-1")
        }
    }
}
