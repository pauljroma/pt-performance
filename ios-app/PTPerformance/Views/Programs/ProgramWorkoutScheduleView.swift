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
    @State private var workoutToPlay: ProgramScheduleWorkout?

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
                    // Store workout before dismissing sheet
                    workoutToPlay = workout
                    selectedWorkout = nil
                }
            )
        }
        .fullScreenCover(item: $workoutToPlay) { workout in
            WorkoutTemplatePlayerWrapper(
                templateId: workout.templateId,
                workoutName: workout.name
            )
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
        .presentationDetents([.medium, .large])
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
    let workoutName: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WorkoutTemplatePlayerViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading \(workoutName)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.isCreatingSession {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Starting workout...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Failed to Load Workout")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let session = viewModel.createdSession, let exercises = viewModel.createdExercises {
                    // Show the workout execution view
                    ManualWorkoutExecutionView(
                        session: session,
                        exercises: exercises,
                        patientId: UUID(uuidString: appState.userId ?? "") ?? UUID(),
                        onComplete: {
                            dismiss()
                        }
                    )
                } else if let template = viewModel.template {
                    // Show template preview with start button
                    templatePreviewView(template)
                } else {
                    // Initial loading state
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadTemplate(templateId: templateId)
        }
    }

    private func templatePreviewView(_ template: SystemWorkoutTemplate) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let description = template.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 16) {
                        if let duration = template.durationMinutes {
                            Label("\(duration) min", systemImage: "clock")
                        }
                        Label("\(template.exerciseCount) exercises", systemImage: "figure.run")
                        if let difficulty = template.difficulty {
                            Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Blocks preview
                ForEach(template.blocks.indices, id: \.self) { index in
                    let block = template.blocks[index]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(block.name)
                            .font(.headline)

                        ForEach(block.exercises.indices, id: \.self) { exIndex in
                            let exercise = block.exercises[exIndex]
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                Spacer()
                                if let sets = exercise.sets, let reps = exercise.reps {
                                    Text("\(sets) x \(reps)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Start button
                Button {
                    Task {
                        if let patientId = appState.userId, let uuid = UUID(uuidString: patientId) {
                            await viewModel.createSession(from: template, patientId: uuid)
                        }
                    }
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
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Workout Template Player View Model

@MainActor
class WorkoutTemplatePlayerViewModel: ObservableObject {
    @Published var template: SystemWorkoutTemplate?
    @Published var isLoading = false
    @Published var isCreatingSession = false
    @Published var errorMessage: String?
    @Published var createdSession: ManualSession?
    @Published var createdExercises: [ManualSessionExercise]?

    private let workoutService = ManualWorkoutService()
    private let supabase = PTSupabaseClient.shared

    func loadTemplate(templateId: UUID) async {
        isLoading = true
        errorMessage = nil
        let logger = DebugLogger.shared

        do {
            logger.log("Loading template: \(templateId)", level: .diagnostic)

            let response = try await supabase.client
                .from("system_workout_templates")
                .select()
                .eq("id", value: templateId.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            template = try decoder.decode(SystemWorkoutTemplate.self, from: response.data)

            logger.log("Loaded template: \(template?.name ?? "unknown")", level: .success)
        } catch {
            logger.log("Failed to load template: \(error.localizedDescription)", level: .error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createSession(from template: SystemWorkoutTemplate, patientId: UUID) async {
        isCreatingSession = true
        errorMessage = nil

        let logger = DebugLogger.shared

        do {
            logger.log("ProgramWorkout: Creating session from template: \(template.name)", level: .diagnostic)

            // 1. Create manual session
            let session = try await workoutService.createManualSession(
                name: template.name,
                patientId: patientId,
                sourceTemplateId: template.id,
                sourceTemplateType: .system
            )

            logger.log("ProgramWorkout: Session created: \(session.id)", level: .success)

            // 2. Add exercises from template blocks
            var exercises: [ManualSessionExercise] = []
            for (blockIndex, block) in template.blocks.enumerated() {
                for (exerciseIndex, exercise) in block.exercises.enumerated() {
                    let sequence = (blockIndex * 100) + exerciseIndex

                    let input = AddManualSessionExerciseInput(
                        manualSessionId: session.id,
                        exerciseTemplateId: nil,
                        exerciseName: exercise.name,
                        blockName: block.name,
                        sequence: sequence,
                        targetSets: exercise.sets ?? 3,
                        targetReps: exercise.reps ?? "10",
                        targetLoad: nil,
                        loadUnit: nil,
                        restPeriodSeconds: nil,
                        notes: exercise.notes
                    )

                    let addedExercise = try await workoutService.addExercise(to: session.id, exercise: input)
                    exercises.append(addedExercise)
                }
            }

            logger.log("ProgramWorkout: Added \(exercises.count) exercises to session", level: .success)

            createdSession = session
            createdExercises = exercises

        } catch {
            logger.log("ProgramWorkout: Failed to create session: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
        }

        isCreatingSession = false
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
