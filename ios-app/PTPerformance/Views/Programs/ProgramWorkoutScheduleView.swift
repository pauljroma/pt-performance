// DARK MODE: See ModeThemeModifier.swift for central theme control
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
    @State private var selectedPhaseSession: BaseballProgramStructure.SessionWithExercises?
    @State private var phaseSessionToPlay: BaseballProgramStructure.SessionWithExercises?

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
                } else if viewModel.usesPhaseBasedStructure {
                    // Use phase-based display for baseball programs
                    phaseBasedContent
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
        .sheet(item: $selectedPhaseSession) { session in
            PhaseSessionStartSheet(
                session: session,
                onStart: {
                    phaseSessionToPlay = session
                    selectedPhaseSession = nil
                }
            )
        }
        .fullScreenCover(item: $workoutToPlay) { workout in
            WorkoutTemplatePlayerWrapper(
                templateId: workout.templateId,
                workoutName: workout.name,
                programName: enrollment.program.title,
                phaseName: nil,
                enrollmentId: enrollment.enrollment.id
            )
        }
        .fullScreenCover(item: $phaseSessionToPlay) { session in
            PhaseSessionPlayerWrapper(
                session: session,
                programName: enrollment.program.title,
                phaseName: nil,
                enrollmentId: enrollment.enrollment.id
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
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.7))

            Text("Program Template")
                .font(.headline)

            Text("This is a program template. To start this program with personalized workouts, ask your therapist to customize it for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Helpful suggestion
            VStack(alignment: .leading, spacing: 8) {
                Label("Share this program with your therapist", systemImage: "person.2")
                Label("They can add customized workouts", systemImage: "plus.circle")
                Label("Check back once workouts are assigned", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }

    // MARK: - Phase-Based Content (for baseball programs)

    @ViewBuilder
    private var phaseBasedContent: some View {
        if let structure = viewModel.programStructure {
            ForEach(structure.phases, id: \.phase.id) { phaseWithSessions in
                PhaseSection(
                    phaseWithSessions: phaseWithSessions,
                    onStartSession: { session in
                        selectedPhaseSession = session
                    }
                )
            }
        }
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
                .id(week.id)
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
                                    .cornerRadius(CornerRadius.xs)
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
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isCurrentWeek ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }
            .accessibilityLabel("Week \(week.weekNumber)\(isCurrentWeek ? ", current week" : ""), \(week.workoutCount) \(week.workoutCount == 1 ? "workout" : "workouts")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") week details")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            // Week Content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(week.activeDays) { day in
                        DayRow(day: day, onWorkoutTap: onWorkoutTap)
                            .id(day.id)
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
                    .id(workout.id)
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
                .cornerRadius(CornerRadius.sm)
                .accessibilityHidden(true)

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
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name)\(workout.durationMinutes.map { ", \($0) minutes" } ?? "")\(workout.difficulty.map { ", \($0.capitalized) difficulty" } ?? "")")
        .accessibilityHint("Double tap to start workout")
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
                        workoutStatItem(icon: "clock", value: "\(duration)", label: "minutes")
                    }

                    if let difficulty = workout.difficulty {
                        workoutStatItem(icon: "chart.bar.fill", value: difficulty.capitalized, label: "difficulty")
                    }

                    if let category = workout.category {
                        workoutStatItem(icon: "tag.fill", value: category.capitalized, label: "category")
                    }
                }

                Spacer()

                // Start Button
                Button {
                    onStart()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .accessibilityHidden(true)
                        Text("Start Workout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(CornerRadius.lg)
                }
                .accessibilityLabel("Start \(workout.name) workout")
                .accessibilityHint("Begins the workout session")
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
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismiss this sheet")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func workoutStatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Workout Template Player Wrapper

struct WorkoutTemplatePlayerWrapper: View {
    let templateId: UUID
    let workoutName: String
    var programName: String = ""
    var phaseName: String? = nil
    var enrollmentId: UUID? = nil

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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
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
                            .accessibilityHidden(true)
                        Text("Start Workout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(CornerRadius.lg)
                }
                .accessibilityLabel("Start \(template.name) workout")
                .accessibilityHint("Begins the workout session with \(template.exerciseCount) exercises")
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

            // 1. Create manual session (program context)
            let session = try await workoutService.createManualSession(
                name: template.name,
                patientId: patientId,
                sourceTemplateId: template.id,
                sourceTemplateType: .system,
                sessionSource: .program
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
    @Published var usesPhaseBasedStructure = false
    @Published var programStructure: BaseballProgramStructure?

    private let service = ProgramLibraryService()

    var totalWorkouts: Int {
        if usesPhaseBasedStructure, let structure = programStructure {
            return structure.phases.reduce(0) { $0 + $1.sessions.count }
        }
        return weeks.reduce(0) { $0 + $1.workoutCount }
    }

    var currentWeek: Int? {
        // Current week calculation based on enrollment start date
        // Implementation notes:
        // - The ViewModel needs access to enrollment.startedAt or enrollment.enrolledAt
        // - To implement: Add enrollmentStartDate property to ViewModel, pass from View in loadSchedule()
        // - Calculate: let weeksSinceStart = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: Date()).weekOfYear ?? 0
        // - Return: min(weeksSinceStart + 1, totalWeeks) clamped to valid range
        // For now, return week 1 until enrollment date is passed to ViewModel
        if usesPhaseBasedStructure {
            return programStructure?.phases.isEmpty == false ? 1 : nil
        }
        guard !weeks.isEmpty else { return nil }
        return 1
    }

    func loadSchedule(programLibraryId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            // First try the new architecture (program_workout_assignments)
            weeks = try await service.fetchProgramWorkoutSchedule(programLibraryId: programLibraryId)

            // If no workouts found, try the old architecture (phases -> sessions)
            if weeks.isEmpty || weeks.allSatisfy({ $0.workoutCount == 0 }) {
                let program = try await service.fetchProgram(id: programLibraryId)

                // Try loading from phases/sessions architecture
                if let programId = program.programId {
                    do {
                        let structure = try await BaseballPackService.shared.fetchProgramStructure(programId: programId)

                        if !structure.phases.isEmpty {
                            programStructure = structure
                            usesPhaseBasedStructure = true
                            // Clear weeks since we're using phase-based
                            weeks = []
                        }
                    } catch {
                        // If this fails too, the program truly has no workouts
                        DebugLogger.shared.warning("ProgramWorkoutScheduleViewModel", "Failed to load phase-based structure: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Phase Section (for baseball programs using old architecture)

private struct PhaseSection: View {
    let phaseWithSessions: BaseballProgramStructure.PhaseWithSessions
    var onStartSession: ((BaseballProgramStructure.SessionWithExercises) -> Void)?

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phaseWithSessions.phase.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let weeks = phaseWithSessions.phase.durationWeeks, weeks > 0 {
                            Text("\(weeks) week\(weeks == 1 ? "" : "s") • \(phaseWithSessions.sessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(phaseWithSessions.sessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)

            // Sessions
            if isExpanded {
                ForEach(phaseWithSessions.sessions, id: \.session.id) { sessionWithExercises in
                    SessionCard(
                        sessionWithExercises: sessionWithExercises,
                        onStartSession: onStartSession
                    )
                }
            }
        }
    }
}

// MARK: - Session Card (for phase-based structure)

private struct SessionCard: View {
    let sessionWithExercises: BaseballProgramStructure.SessionWithExercises
    var onStartSession: ((BaseballProgramStructure.SessionWithExercises) -> Void)?

    @State private var showExercises = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Session Header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showExercises.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionWithExercises.session.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                if sessionWithExercises.session.isThrowingDay == true {
                                    Label("Throwing", systemImage: "figure.baseball")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }

                                Text("\(sessionWithExercises.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: showExercises ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                // Start button
                Button {
                    HapticFeedback.light()
                    onStartSession?(sessionWithExercises)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)

            // Exercises
            if showExercises {
                VStack(spacing: 6) {
                    ForEach(sessionWithExercises.exercises) { exercise in
                        PhaseExerciseRow(exercise: exercise)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Phase Exercise Row (for phase-based structure)

private struct PhaseExerciseRow: View {
    let exercise: BaseballSessionExercise

    var body: some View {
        HStack(spacing: 12) {
            // Sequence number
            Text("\(exercise.sequence)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))

            VStack(alignment: .leading, spacing: 2) {
                // Exercise name
                Text(exercise.exerciseTemplate?.name ?? "Exercise")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                // Sets x Reps
                HStack(spacing: 4) {
                    if let sets = exercise.targetSets {
                        Text("\(sets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let reps = exercise.targetReps {
                        Text("× \(reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let label = exercise.blockLabel {
                        Text("• \(label)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Phase Session Start Sheet

struct PhaseSessionStartSheet: View {
    let session: BaseballProgramStructure.SessionWithExercises
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Session Icon
                Image(systemName: session.session.isThrowingDay == true ? "figure.baseball" : "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                // Session Info
                VStack(spacing: 8) {
                    Text(session.session.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let notes = session.session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal)

                // Stats
                HStack(spacing: 24) {
                    statItem(icon: "figure.run", value: "\(session.exercises.count)", label: "exercises")

                    if session.session.isThrowingDay == true {
                        statItem(icon: "figure.baseball", value: "Yes", label: "throwing")
                    }
                }

                // Exercises preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(session.exercises.prefix(5)) { exercise in
                                HStack {
                                    Text(exercise.exerciseTemplate?.name ?? "Exercise")
                                        .font(.subheadline)
                                    Spacer()
                                    if let sets = exercise.targetSets, let reps = exercise.targetReps {
                                        Text("\(sets) × \(reps)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(CornerRadius.sm)
                            }
                            if session.exercises.count > 5 {
                                Text("+ \(session.exercises.count - 5) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                // Start Button
                Button {
                    onStart()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .accessibilityHidden(true)
                        Text("Start Workout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(CornerRadius.lg)
                }
                .accessibilityLabel("Start \(session.session.name) workout")
                .accessibilityHint("Begins the workout session with \(session.exercises.count) exercises")
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
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismiss this sheet")
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
                .accessibilityHidden(true)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Phase Session Player Wrapper

struct PhaseSessionPlayerWrapper: View {
    let session: BaseballProgramStructure.SessionWithExercises
    var programName: String = ""
    var phaseName: String? = nil
    var enrollmentId: UUID? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PhaseSessionPlayerViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isCreatingSession {
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
                        Text("Failed to Start Workout")
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
                } else if let createdSession = viewModel.createdSession,
                          let createdExercises = viewModel.createdExercises {
                    // Show the workout execution view
                    ManualWorkoutExecutionView(
                        session: createdSession,
                        exercises: createdExercises,
                        patientId: UUID(uuidString: appState.userId ?? "") ?? UUID(),
                        onComplete: {
                            dismiss()
                        }
                    )
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
            .navigationTitle(session.session.name)
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
            if let patientId = appState.userId, let uuid = UUID(uuidString: patientId) {
                await viewModel.createSession(from: session, patientId: uuid)
            }
        }
    }
}

// MARK: - Phase Session Player View Model

@MainActor
class PhaseSessionPlayerViewModel: ObservableObject {
    @Published var isCreatingSession = false
    @Published var errorMessage: String?
    @Published var createdSession: ManualSession?
    @Published var createdExercises: [ManualSessionExercise]?

    private let workoutService = ManualWorkoutService()

    func createSession(from sessionData: BaseballProgramStructure.SessionWithExercises, patientId: UUID) async {
        isCreatingSession = true
        errorMessage = nil

        let logger = DebugLogger.shared

        do {
            logger.log("PhaseSession: Creating session from: \(sessionData.session.name)", level: .diagnostic)

            // 1. Create manual session (program context - from phase session)
            let session = try await workoutService.createManualSession(
                name: sessionData.session.name,
                patientId: patientId,
                sourceTemplateId: nil,
                sourceTemplateType: nil,
                sessionSource: .program
            )

            logger.log("PhaseSession: Session created: \(session.id)", level: .success)

            // 2. Add exercises from the phase session
            var exercises: [ManualSessionExercise] = []
            for (index, exercise) in sessionData.exercises.enumerated() {
                let repsString: String?
                if let reps = exercise.targetReps {
                    repsString = String(reps)
                } else {
                    repsString = "10"
                }

                let input = AddManualSessionExerciseInput(
                    manualSessionId: session.id,
                    exerciseTemplateId: exercise.exerciseTemplateId,
                    exerciseName: exercise.exerciseTemplate?.name ?? "Exercise \(index + 1)",
                    blockName: exercise.blockLabel,
                    sequence: index,
                    targetSets: exercise.targetSets ?? 3,
                    targetReps: repsString,
                    targetLoad: nil,
                    loadUnit: nil,
                    restPeriodSeconds: nil,
                    notes: exercise.notes
                )

                let addedExercise = try await workoutService.addExercise(to: session.id, exercise: input)
                exercises.append(addedExercise)
            }

            logger.log("PhaseSession: Added \(exercises.count) exercises to session", level: .success)

            createdSession = session
            createdExercises = exercises

        } catch {
            logger.log("PhaseSession: Failed to create session: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
        }

        isCreatingSession = false
    }
}

// MARK: - Identifiable conformance for SessionWithExercises

extension BaseballProgramStructure.SessionWithExercises: Identifiable {
    public var id: UUID { session.id }
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
