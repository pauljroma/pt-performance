import SwiftUI

struct TodaySessionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TodaySessionViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading today's session...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Retry") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    }
                    .padding()
                } else if viewModel.session == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("No Session Today")
                            .font(.title2)
                            .bold()

                        Text("Great job! You're all caught up. Enjoy your rest day!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Session Header
                            if let session = viewModel.session {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(session.dateDisplay)
                                        .font(.headline)
                                        .foregroundColor(.secondary)

                                    Text("Session #\(session.session_number)")
                                        .font(.title)
                                        .bold()

                                    HStack {
                                        Image(systemName: session.is_completed ? "checkmark.circle.fill" : "circle")
                                        Text(session.completionStatus)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(session.is_completed ? .green : .blue)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }

                            // Exercise List
                            if viewModel.exercises.isEmpty {
                                Text("No exercises in this session")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.exercises) { exercise in
                                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                            ExerciseRow(exercise: exercise)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Today's Session")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.fetchTodaySession()
            }
        }
    }
}

/// Exercise row component
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 16) {
            // Exercise order badge
            Text("\(exercise.exercise_order)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())

            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise_name ?? "Exercise \(exercise.exercise_order)")
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(exercise.setsDisplay, systemImage: "repeat")
                    Label(exercise.repsDisplay + " reps", systemImage: "number")
                    Label(exercise.loadDisplay, systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Exercise detail view placeholder
struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(exercise.exercise_name ?? "Exercise")
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Sets", value: exercise.setsDisplay)
                    DetailRow(label: "Reps", value: exercise.repsDisplay)
                    DetailRow(label: "Load", value: exercise.loadDisplay)

                    if let rest = exercise.rest_seconds {
                        DetailRow(label: "Rest", value: "\(rest) seconds")
                    }

                    if let notes = exercise.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Log exercise button (placeholder for ACP-94)
                NavigationLink(destination: Text("Exercise logging (ACP-94)")) {
                    Text("Log This Exercise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Exercise Detail")
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
