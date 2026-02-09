//
//  ActiveProgramDetailView.swift
//  PTPerformance
//
//  Comprehensive view showing a patient's enrolled program with its full structure
//  including phases, weeks, and scheduled workouts with progress tracking.
//

import SwiftUI

// MARK: - Active Program Detail View

struct ActiveProgramDetailView: View {
    let enrollment: EnrollmentWithProgram
    @StateObject private var viewModel: ActiveProgramDetailViewModel
    @Environment(\.dismiss) private var dismiss

    // Sheet states
    @State private var showLeaveConfirmation = false
    @State private var isProcessing = false
    @State private var selectedWorkout: ProgramScheduleWorkout?
    @State private var workoutToPlay: ProgramScheduleWorkout?
    @State private var selectedPhaseSession: BaseballProgramStructure.SessionWithExercises?
    @State private var phaseSessionToPlay: BaseballProgramStructure.SessionWithExercises?

    init(enrollment: EnrollmentWithProgram) {
        self.enrollment = enrollment
        self._viewModel = StateObject(wrappedValue: ActiveProgramDetailViewModel(enrollment: enrollment))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Program Header
                    programHeader

                    // Progress Overview
                    progressOverview

                    // Phase Timeline
                    phaseTimeline

                    // Current Phase Detail with Weeks
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.usesPhaseBasedStructure {
                        phaseBasedContent
                    } else if !viewModel.weeks.isEmpty {
                        weeksContent
                    } else {
                        emptyProgramView
                    }

                    // Program Options
                    programOptionsSection
                }
                .padding()
            }
            .navigationTitle("Active Program")
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
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutStartSheet(
                    workout: workout,
                    onStart: {
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
                    workoutName: workout.name
                )
            }
            .fullScreenCover(item: $phaseSessionToPlay) { session in
                PhaseSessionPlayerWrapper(session: session)
            }
            .confirmationDialog(
                "Leave Program",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave Program", role: .destructive) {
                    Task {
                        isProcessing = true
                        await viewModel.leaveProgram()
                        isProcessing = false
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to leave \"\(enrollment.program.title)\"? Your progress will be saved and you can re-enroll later.")
            }
            .task {
                await viewModel.loadProgramStructure()
            }
        }
    }

    // MARK: - Program Header

    private var programHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Badge
            HStack {
                ProgramCategoryBadge(category: enrollment.program.category)

                // Enrollment status
                HStack(spacing: 4) {
                    Image(systemName: enrollment.enrollment.enrollmentStatus.icon)
                        .font(.caption2)
                    Text(enrollment.enrollment.enrollmentStatus.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(enrollment.enrollment.enrollmentStatus.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(enrollment.enrollment.enrollmentStatus.color.opacity(0.15))
                .cornerRadius(6)

                Spacer()
            }

            // Title
            Text(enrollment.program.title)
                .font(.title2)
                .fontWeight(.bold)

            // Author and dates
            HStack(spacing: 16) {
                if let author = enrollment.program.author {
                    Label(author, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Label(enrollment.program.formattedDuration, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgramDifficultyBadge(difficulty: enrollment.program.difficultyLevel)
            }

            // Enrollment date
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text("Enrolled \(enrollment.enrollment.enrolledAt, style: .date)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }

    // MARK: - Progress Overview

    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.SectionHeaders.yourProgress)
                .font(.headline)

            HStack(spacing: 20) {
                // Current Week
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(viewModel.currentWeek)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("of \(enrollment.program.durationWeeks)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.progressPercentage) / 100)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.progressPercentage)

                    VStack(spacing: 0) {
                        Text("\(viewModel.progressPercentage)%")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("done")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel("\(viewModel.progressPercentage) percent complete")
            }

            // Workout Stats
            HStack(spacing: 16) {
                statCard(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.completedWorkouts)",
                    label: "Completed",
                    color: .green
                )

                statCard(
                    icon: "clock.fill",
                    value: "\(viewModel.remainingWorkouts)",
                    label: "Remaining",
                    color: .blue
                )

                statCard(
                    icon: "flame.fill",
                    value: viewModel.daysRemainingDisplay,
                    label: "Time Left",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Phase Timeline

    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Phases")
                .font(.headline)

            if viewModel.phases.isEmpty && !viewModel.isLoading {
                Text("Phase information not available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.phases) { phase in
                            PhaseTimelineCard(
                                phase: phase,
                                isCurrentPhase: phase.phaseNumber == viewModel.currentPhase,
                                isCompleted: phase.phaseNumber < viewModel.currentPhase
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading program structure...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Couldn't Load Program")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadProgramStructure()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty Program View

    private var emptyProgramView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.7))

            Text("Program Template")
                .font(.headline)

            Text("This is a program template. Workouts will appear once your therapist customizes it for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phase-Based Content

    @ViewBuilder
    private var phaseBasedContent: some View {
        if let structure = viewModel.programStructure {
            VStack(alignment: .leading, spacing: 16) {
                Text("Workout Schedule")
                    .font(.headline)

                ForEach(structure.phases, id: \.phase.id) { phaseWithSessions in
                    ProgramPhaseSection(
                        phaseWithSessions: phaseWithSessions,
                        isCurrentPhase: phaseWithSessions.phase.sequence == viewModel.currentPhase,
                        onStartSession: { session in
                            selectedPhaseSession = session
                        }
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(DesignTokens.cornerRadiusMedium)
        }
    }

    // MARK: - Weeks Content

    private var weeksContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.SectionHeaders.workoutSchedule)
                .font(.headline)

            ForEach(viewModel.weeks) { week in
                ProgramWeekSection(
                    week: week,
                    isCurrentWeek: week.weekNumber == viewModel.currentWeek,
                    onWorkoutTap: { workout in
                        selectedWorkout = workout
                    }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }

    // MARK: - Program Options Section

    private var programOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Options")
                .font(.headline)

            Button {
                HapticFeedback.warning()
                showLeaveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "door.left.hand.open")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Leave Program")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)

                        Text("Stop participating in this program")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .disabled(isProcessing)
            .accessibilityLabel("Leave program")
            .accessibilityHint("Double tap to stop participating in this program")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if viewModel.progressPercentage >= 75 {
            return .green
        } else if viewModel.progressPercentage >= 50 {
            return .blue
        } else if viewModel.progressPercentage >= 25 {
            return .orange
        } else {
            return .purple
        }
    }
}

// MARK: - Phase Timeline Card

private struct PhaseTimelineCard: View {
    let phase: ProgramPhasePreview
    let isCurrentPhase: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Phase Number Badge
            HStack {
                Text("\(phase.phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(badgeColor))

                if isCurrentPhase {
                    Text("CURRENT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(3)
                }

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Phase Name
            Text(phase.phaseName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Week Range
            Text(phase.formattedWeekRange)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Workout Count
            Text("\(phase.workoutCount) workouts")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(width: 120)
        .background(isCurrentPhase ? Color.blue.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrentPhase ? Color.blue : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase \(phase.phaseNumber): \(phase.phaseName), \(phase.formattedWeekRange), \(phase.workoutCount) workouts\(isCurrentPhase ? ", current phase" : "")\(isCompleted ? ", completed" : "")")
    }

    private var badgeColor: Color {
        if isCompleted {
            return .green
        } else if isCurrentPhase {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Program Phase Section (for phase-based programs)

private struct ProgramPhaseSection: View {
    let phaseWithSessions: BaseballProgramStructure.PhaseWithSessions
    let isCurrentPhase: Bool
    var onStartSession: ((BaseballProgramStructure.SessionWithExercises) -> Void)?

    @State private var isExpanded: Bool

    init(phaseWithSessions: BaseballProgramStructure.PhaseWithSessions, isCurrentPhase: Bool, onStartSession: ((BaseballProgramStructure.SessionWithExercises) -> Void)?) {
        self.phaseWithSessions = phaseWithSessions
        self.isCurrentPhase = isCurrentPhase
        self.onStartSession = onStartSession
        self._isExpanded = State(initialValue: isCurrentPhase)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    // Phase indicator
                    Circle()
                        .fill(isCurrentPhase ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(phaseWithSessions.phase.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if isCurrentPhase {
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

                        Text("\(phaseWithSessions.sessions.count) sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(isCurrentPhase ? Color.blue.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Phase: \(phaseWithSessions.phase.name)\(isCurrentPhase ? ", current phase" : ""), \(phaseWithSessions.sessions.count) sessions")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

            // Sessions
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(phaseWithSessions.sessions, id: \.session.id) { sessionWithExercises in
                        ProgramSessionCard(
                            sessionWithExercises: sessionWithExercises,
                            onStart: {
                                onStartSession?(sessionWithExercises)
                            }
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Program Session Card

private struct ProgramSessionCard: View {
    let sessionWithExercises: BaseballProgramStructure.SessionWithExercises
    let onStart: () -> Void

    @State private var showExercises = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Session Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionWithExercises.session.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

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

                // Expand/Collapse button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showExercises.toggle()
                    }
                } label: {
                    Image(systemName: showExercises ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Start Button
                Button {
                    HapticFeedback.light()
                    onStart()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(sessionWithExercises.session.name)")
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .adaptiveShadow(Shadow.subtle)

            // Exercises list
            if showExercises {
                VStack(spacing: 4) {
                    ForEach(sessionWithExercises.exercises) { exercise in
                        HStack(spacing: 10) {
                            Text("\(exercise.sequence)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.blue))

                            Text(exercise.exerciseTemplate?.name ?? "Exercise")
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            if let sets = exercise.targetSets, let reps = exercise.targetReps {
                                Text("\(sets) x \(reps)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
}

// MARK: - Program Week Section (for week-based programs)

private struct ProgramWeekSection: View {
    let week: ProgramScheduleWeek
    let isCurrentWeek: Bool
    let onWorkoutTap: (ProgramScheduleWorkout) -> Void

    @State private var isExpanded: Bool

    init(week: ProgramScheduleWeek, isCurrentWeek: Bool, onWorkoutTap: @escaping (ProgramScheduleWorkout) -> Void) {
        self.week = week
        self.isCurrentWeek = isCurrentWeek
        self.onWorkoutTap = onWorkoutTap
        self._isExpanded = State(initialValue: isCurrentWeek)
    }

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
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
                .background(isCurrentWeek ? Color.blue.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Week \(week.weekNumber)\(isCurrentWeek ? ", current week" : ""), \(week.workoutCount) workouts")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

            // Week Content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(week.activeDays) { day in
                        ProgramDayRow(day: day, onWorkoutTap: onWorkoutTap)
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
}

// MARK: - Program Day Row

private struct ProgramDayRow: View {
    let day: ProgramScheduleDay
    let onWorkoutTap: (ProgramScheduleWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            ForEach(day.workouts) { workout in
                ProgramWorkoutCard(workout: workout)
                    .onTapGesture {
                        HapticFeedback.light()
                        onWorkoutTap(workout)
                    }
            }
        }
    }
}

// MARK: - Program Workout Card

private struct ProgramWorkoutCard: View {
    let workout: ProgramScheduleWorkout

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.15))
                .cornerRadius(8)

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
        .cornerRadius(10)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name)\(workout.durationMinutes.map { ", \($0) minutes" } ?? "")")
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

// MARK: - Preview

#if DEBUG
struct ActiveProgramDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview requires EnrollmentWithProgram data")
            .padding()
    }
}
#endif
