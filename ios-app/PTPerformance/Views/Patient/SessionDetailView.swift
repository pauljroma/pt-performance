import SwiftUI

// MARK: - BUILD 296: Session Detail View (ACP-588)

/// Full detail view for a workout from history — shows stats + exercise breakdown
struct SessionDetailView: View {
    let workout: WorkoutHistoryItem
    let patientId: String

    @StateObject private var viewModel = SessionDetailViewModel()
    @State private var selectedExercise: ExerciseLogDetail?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Stats grid
                statsGrid

                // Exercise list
                exerciseListSection
            }
            .padding()
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetail()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseTemplateInfoSheet(
                exerciseName: exercise.exerciseName,
                exerciseTemplateId: exercise.exerciseTemplateId
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if workout.isManual {
                        Text("Manual Workout")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                if workout.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            if let count = workout.exerciseCount, count > 0 {
                StatTile(
                    title: "Exercises",
                    value: "\(count)",
                    icon: "list.bullet",
                    color: .blue
                )
            }

            if let duration = workout.duration, duration > 0 {
                StatTile(
                    title: "Duration",
                    value: "\(duration) min",
                    icon: "clock.fill",
                    color: .orange
                )
            }

            if let volume = workout.volume, volume > 0 {
                StatTile(
                    title: "Volume",
                    value: formatVolume(volume),
                    icon: "scalemass.fill",
                    color: .purple
                )
            }

            if let pain = workout.avgPain {
                StatTile(
                    title: "Avg Pain",
                    value: String(format: "%.1f", pain),
                    icon: "heart.fill",
                    color: painColor(pain)
                )
            }
        }
    }

    // MARK: - Exercise List

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isLoading {
                ProgressView("Loading exercises...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if viewModel.exerciseLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No exercise data recorded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.exerciseLogs) { log in
                    Button {
                        if log.exerciseTemplateId != nil {
                            selectedExercise = log
                        }
                    } label: {
                        ExerciseLogRow(log: log)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadDetail() async {
        switch workout {
        case .prescribed(let session):
            await viewModel.fetchPrescribedDetail(
                sessionId: session.id,
                patientId: patientId
            )
        case .manual(let manual):
            await viewModel.fetchManualDetail(workoutId: manual.id)
        }
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Log Row

struct ExerciseLogRow: View {
    let log: ExerciseLogDetail

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(log.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if log.hasVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text("\(log.actualSets) sets x \(log.repsDisplay) @ \(log.loadDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .italic()
                }
            }

            Spacer()

            // RPE and Pain indicators
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("RPE")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(log.rpe)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(rpeColor(Double(log.rpe)))
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                    Text("\(log.painScore)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(painColor(Double(log.painScore)))
            }

            if log.exerciseTemplateId != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private func rpeColor(_ rpe: Double) -> Color {
        switch rpe {
        case 0..<4: return .green
        case 4..<7: return .yellow
        case 7..<9: return .orange
        default: return .red
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }
}
