//
//  ProgramWorkoutScheduleView.swift
//  PTPerformance
//
//  BUILD 347: Weekly workout schedule view for enrolled programs
//  Shows workouts organized by week/day with ability to start workouts
//

import SwiftUI

// MARK: - Program Workout Schedule View

struct ProgramWorkoutScheduleView: View {
    let enrollment: EnrollmentWithProgram
    @StateObject private var viewModel = ProgramWorkoutScheduleViewModel()
    @State private var selectedWorkout: ProgramScheduleWorkout?
    @State private var showingWorkoutPlayer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.weeks.isEmpty {
                    emptyView
                } else {
                    weeksContent
                }
            }
            .padding()
        }
        .navigationTitle("Weekly Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedWorkout) { workout in
            WorkoutStartSheet(
                workout: workout,
                onStart: {
                    selectedWorkout = nil
                    showingWorkoutPlayer = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingWorkoutPlayer) {
            if let workout = selectedWorkout {
                // Navigate to workout player with template
                WorkoutTemplatePlayerWrapper(templateId: workout.templateId)
            }
        }
        .task {
            await viewModel.loadSchedule(programLibraryId: enrollment.program.id)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(enrollment.program.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label("\(enrollment.program.durationWeeks) weeks", systemImage: "calendar")
                Label("\(viewModel.totalWorkouts) workouts", systemImage: "figure.run")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            // Current week indicator
            if let currentWeek = viewModel.currentWeek {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                    Text("You're on Week \(currentWeek)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading workout schedule...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Couldn't Load Schedule")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadSchedule(programLibraryId: enrollment.program.id)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Workouts Scheduled")
                .font(.headline)

            Text("This program doesn't have any workouts assigned yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Weeks Content

    private var weeksContent: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.weeks) { week in
                WeekSection(
                    week: week,
                    isCurrentWeek: week.weekNumber == viewModel.currentWeek,
                    onWorkoutTap: { workout in
                        selectedWorkout = workout
                    }
                )
            }
        }
    }
}

// MARK: - Week Section

private struct WeekSection: View {
    let week: ProgramScheduleWeek
    let isCurrentWeek: Bool
    let onWorkoutTap: (ProgramScheduleWorkout) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Week \(week.weekNumber)")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if isCurrentWeek {
                                Text("CURRENT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }

                        Text("\(week.workoutCount) workout\(week.workoutCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isCurrentWeek ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(10)
            }

            // Week Content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(week.activeDays) { day in
                        DayRow(day: day, onWorkoutTap: onWorkoutTap)
                    }

                    if week.activeDays.isEmpty {
                        Text("Rest week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.leading, 12)
            }
        }
    }

    init(week: ProgramScheduleWeek, isCurrentWeek: Bool, onWorkoutTap: @escaping (ProgramScheduleWorkout) -> Void) {
        self.week = week
        self.isCurrentWeek = isCurrentWeek
        self.onWorkoutTap = onWorkoutTap
        // Auto-expand current week
        _isExpanded = State(initialValue: isCurrentWeek)
    }
}

// MARK: - Day Row

private struct DayRow: View {
    let day: ProgramScheduleDay
    let onWorkoutTap: (ProgramScheduleWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.dayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            ForEach(day.workouts) { workout in
                WorkoutCard(workout: workout)
                    .onTapGesture {
                        HapticFeedback.light()
                        onWorkoutTap(workout)
                    }
            }
        }
    }
}

// MARK: - Workout Card

private struct WorkoutCard: View {
    let workout: ProgramScheduleWorkout

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(categoryColor)
                .frame(width: 44, height: 44)
                .background(categoryColor.opacity(0.15))
                .cornerRadius(10)

            // Workout Info
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let duration = workout.durationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                    }

                    if let difficulty = workout.difficulty {
                        Text(difficulty.capitalized)
                            .foregroundColor(difficultyColor(difficulty))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Start Button
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    private var categoryIcon: String {
        switch workout.category?.lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio": return "heart.fill"
        case "mobility": return "figure.flexibility"
        case "recovery": return "bed.double.fill"
        default: return "figure.run"
        }
    }

    private var categoryColor: Color {
        switch workout.category?.lowercased() {
        case "strength": return .orange
        case "cardio": return .red
        case "mobility": return .purple
        case "recovery": return .green
        default: return .blue
        }
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Workout Start Sheet

struct WorkoutStartSheet: View {
    let workout: ProgramScheduleWorkout
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Workout Icon
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                // Workout Info
                VStack(spacing: 8) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let description = workout.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal)

                // Stats
                HStack(spacing: 24) {
                    if let duration = workout.durationMinutes {
                        statItem(icon: "clock", value: "\(duration)", label: "minutes")
                    }

                    if let difficulty = workout.difficulty {
                        statItem(icon: "chart.bar.fill", value: difficulty.capitalized, label: "difficulty")
                    }

                    if let category = workout.category {
                        statItem(icon: "tag.fill", value: category.capitalized, label: "category")
                    }
                }

                Spacer()

                // Start Button
                Button {
                    onStart()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Ready to Start?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Template Player Wrapper

struct WorkoutTemplatePlayerWrapper: View {
    let templateId: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // TODO: Connect to ManualWorkoutPlayerView with the template
            VStack {
                Text("Starting workout...")
                    .font(.headline)

                Text("Template ID: \(templateId.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Close") {
                    dismiss()
                }
                .padding(.top)
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class ProgramWorkoutScheduleViewModel: ObservableObject {
    @Published var weeks: [ProgramScheduleWeek] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = ProgramLibraryService()

    var totalWorkouts: Int {
        weeks.reduce(0) { $0 + $1.workoutCount }
    }

    var currentWeek: Int? {
        // TODO: Calculate based on enrollment start date
        // For now, return week 1
        guard !weeks.isEmpty else { return nil }
        return 1
    }

    func loadSchedule(programLibraryId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            weeks = try await service.fetchProgramWorkoutSchedule(programLibraryId: programLibraryId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramWorkoutScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Text("Preview not available")
        }
    }
}
#endif
