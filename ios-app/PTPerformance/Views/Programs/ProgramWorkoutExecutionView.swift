//
//  ProgramWorkoutExecutionView.swift
//  PTPerformance
//
//  Workout execution flow for patients completing workouts from enrolled programs.
//  Provides a streamlined experience for: Start Workout -> Do Exercises -> Complete Workout
//

import SwiftUI
import Combine

// MARK: - View Model

@MainActor
class ProgramWorkoutExecutionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var session: ManualSession
    @Published var exercises: [ManualSessionExercise]
    @Published var currentExerciseIndex: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCompletionConfirmation = false
    @Published var isWorkoutCompleted = false
    @Published var isTimerVisible: Bool = true

    // Current exercise input fields
    @Published var actualSets: Int = 0
    @Published var repsPerSet: [Int] = []
    @Published var weightPerSet: [Double] = []
    @Published var loadUnit: String = "lbs"
    @Published var rpe: Double = 5.0
    @Published var painScore: Double = 0.0
    @Published var notes: String = ""

    // Rest timer
    @Published var showRestTimer = false
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var restTotalTime: TimeInterval = 0

    // Exercise completion tracking
    @Published var completedExerciseIds: Set<UUID> = []
    @Published var skippedExerciseIds: Set<UUID> = []

    // MARK: - Private Properties

    private let service: ManualWorkoutService
    private let programService: ProgramLibraryService
    let patientId: UUID
    private let enrollmentId: UUID?
    private let programName: String
    private let phaseName: String?
    private var timerCancellable: AnyCancellable?
    private var restTimerCancellable: AnyCancellable?
    private var startTime: Date?

    // MARK: - Computed Properties

    var workoutName: String {
        session.name ?? "Workout"
    }

    var headerSubtitle: String {
        var parts: [String] = []
        parts.append(programName)
        if let phase = phaseName {
            parts.append(phase)
        }
        return parts.joined(separator: " - ")
    }

    var totalExercises: Int {
        exercises.count
    }

    var completedCount: Int {
        completedExerciseIds.count
    }

    var progressText: String {
        "\(completedCount) / \(totalExercises)"
    }

    var progressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedCount) / Double(totalExercises)
    }

    var elapsedTimeDisplay: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentExercise: ManualSessionExercise? {
        guard currentExerciseIndex >= 0 && currentExerciseIndex < exercises.count else {
            return nil
        }
        return exercises[currentExerciseIndex]
    }

    var canCompleteWorkout: Bool {
        completedCount > 0
    }

    var allExercisesCompleted: Bool {
        completedCount == totalExercises
    }

    var actualLoad: Double? {
        guard !weightPerSet.isEmpty else { return nil }
        let nonZeroWeights = weightPerSet.filter { $0 > 0 }
        guard !nonZeroWeights.isEmpty else { return nil }
        return nonZeroWeights.reduce(0, +) / Double(nonZeroWeights.count)
    }

    // MARK: - Metrics

    var totalVolume: Double {
        var volume: Double = 0
        for exercise in exercises {
            if completedExerciseIds.contains(exercise.id) {
                if let actualReps = exercise.actualReps, let actualLoad = exercise.actualLoad {
                    let totalReps = actualReps.reduce(0, +)
                    volume += Double(totalReps) * actualLoad
                }
            }
        }
        return volume
    }

    var volumeDisplay: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk lbs", totalVolume / 1000)
        }
        return "\(Int(totalVolume)) lbs"
    }

    var averageRPE: Double? {
        let completedWithRPE = exercises.filter { completedExerciseIds.contains($0.id) && $0.rpe != nil }
        guard !completedWithRPE.isEmpty else { return nil }
        let totalRPE = completedWithRPE.compactMap { $0.rpe }.reduce(0, +)
        return totalRPE / Double(completedWithRPE.count)
    }

    var averagePain: Double? {
        let completedWithPain = exercises.filter { completedExerciseIds.contains($0.id) && $0.painScore != nil }
        guard !completedWithPain.isEmpty else { return nil }
        let totalPain = completedWithPain.compactMap { $0.painScore }.reduce(0, +)
        return totalPain / Double(completedWithPain.count)
    }

    // MARK: - Initialization

    init(
        session: ManualSession,
        exercises: [ManualSessionExercise],
        patientId: UUID,
        programName: String,
        phaseName: String? = nil,
        enrollmentId: UUID? = nil,
        service: ManualWorkoutService = ManualWorkoutService(),
        programService: ProgramLibraryService = ProgramLibraryService()
    ) {
        self.session = session
        self.exercises = exercises.sorted { $0.sequence < $1.sequence }
        self.patientId = patientId
        self.programName = programName
        self.phaseName = phaseName
        self.enrollmentId = enrollmentId
        self.service = service
        self.programService = programService

        // Initialize with first exercise defaults
        if let firstExercise = self.exercises.first {
            setupInputFields(for: firstExercise)
        }
    }

    // MARK: - Timer Management

    func startTimer() {
        startTime = Date()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        restTotalTime = TimeInterval(seconds)
        restTimeRemaining = restTotalTime
        showRestTimer = true

        restTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.skipRestTimer()
                }
            }
    }

    func skipRestTimer() {
        restTimerCancellable?.cancel()
        restTimerCancellable = nil
        showRestTimer = false
        restTimeRemaining = 0
    }

    // MARK: - Exercise Navigation

    func setupInputFields(for exercise: ManualSessionExercise) {
        let sets = exercise.targetSets ?? 3
        actualSets = sets
        repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: sets)
        weightPerSet = Array(repeating: exercise.targetLoad ?? 0, count: sets)
        loadUnit = exercise.loadUnit ?? "lbs"
        rpe = 5.0
        painScore = 0.0
        notes = ""
    }

    func moveToNextExercise() {
        // Find next incomplete exercise
        for (index, exercise) in exercises.enumerated() {
            if !completedExerciseIds.contains(exercise.id) && !skippedExerciseIds.contains(exercise.id) {
                currentExerciseIndex = index
                setupInputFields(for: exercise)
                return
            }
        }

        // All exercises completed
        if allExercisesCompleted {
            showCompletionConfirmation = true
        }
    }

    func selectExercise(_ exercise: ManualSessionExercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentExerciseIndex = index
        setupInputFields(for: exercise)
    }

    func isExerciseCompleted(_ exercise: ManualSessionExercise) -> Bool {
        completedExerciseIds.contains(exercise.id)
    }

    func isExerciseSkipped(_ exercise: ManualSessionExercise) -> Bool {
        skippedExerciseIds.contains(exercise.id)
    }

    func isCurrentExercise(_ exercise: ManualSessionExercise) -> Bool {
        currentExercise?.id == exercise.id
    }

    // MARK: - Exercise Actions

    func completeCurrentExercise() async {
        guard let exercise = currentExercise else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Log the exercise to database
            try await service.logManualExercise(
                manualSessionExerciseId: exercise.id,
                patientId: patientId,
                actualSets: actualSets,
                actualReps: Array(repsPerSet.prefix(actualSets)),
                actualLoad: actualLoad,
                loadUnit: loadUnit,
                rpe: Int(rpe),
                painScore: Int(painScore),
                notes: notes.isEmpty ? nil : notes
            )

            // Update local exercise state
            if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                exercises[index].actualSets = actualSets
                exercises[index].actualReps = Array(repsPerSet.prefix(actualSets))
                exercises[index].actualLoad = actualLoad
                exercises[index].rpe = rpe
                exercises[index].painScore = painScore
            }

            completedExerciseIds.insert(exercise.id)

            // Haptic feedback
            HapticFeedback.success()

            // Start rest timer if exercise has rest period
            if let restSeconds = exercise.restPeriodSeconds, restSeconds > 0 {
                startRestTimer(seconds: restSeconds)
            } else {
                moveToNextExercise()
            }

            DebugLogger.shared.log("Completed exercise: \(exercise.exerciseName)", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to log exercise: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to save exercise: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func quickCompleteExercise() async {
        // Complete with prescribed values
        guard let exercise = currentExercise else { return }

        let sets = exercise.targetSets ?? 3
        actualSets = sets
        repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: sets)
        weightPerSet = Array(repeating: exercise.targetLoad ?? 0, count: sets)

        await completeCurrentExercise()
    }

    func skipCurrentExercise() {
        guard let exercise = currentExercise else { return }

        skippedExerciseIds.insert(exercise.id)
        HapticFeedback.medium()
        moveToNextExercise()

        DebugLogger.shared.log("Skipped exercise: \(exercise.exerciseName)", level: .diagnostic)
    }

    // MARK: - Workout Completion

    func completeWorkout() async {
        isLoading = true
        errorMessage = nil

        let durationMinutes = Int(elapsedTime / 60)

        do {
            // Update session as completed
            _ = try await service.completeWorkout(
                session.id,
                totalVolume: totalVolume,
                avgRpe: averageRPE,
                avgPain: averagePain,
                durationMinutes: durationMinutes
            )

            // Update program progress if enrollment is tracked
            if let enrollmentId = enrollmentId {
                // Calculate new progress (simplified - could be enhanced)
                // This would ideally count completed workouts / total workouts
                try? await programService.updateProgress(enrollmentId: enrollmentId, progress: 0) // Progress calculation done server-side
            }

            // Record workout completion for program progress tracking
            if let templateId = session.sourceTemplateId {
                try? await programService.recordWorkoutCompletion(
                    patientId: patientId.uuidString,
                    templateId: templateId
                )
            }

            stopTimer()
            isWorkoutCompleted = true
            HapticFeedback.success()

            DebugLogger.shared.log("Workout completed: \(workoutName), duration: \(durationMinutes) min", level: .success)
        } catch {
            DebugLogger.shared.log("Failed to complete workout: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Main View

struct ProgramWorkoutExecutionView: View {
    @StateObject private var viewModel: ProgramWorkoutExecutionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showExitConfirmation = false
    @State private var showCompletionSheet = false

    init(
        session: ManualSession,
        exercises: [ManualSessionExercise],
        patientId: UUID,
        programName: String,
        phaseName: String? = nil,
        enrollmentId: UUID? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ProgramWorkoutExecutionViewModel(
            session: session,
            exercises: exercises,
            patientId: patientId,
            programName: programName,
            phaseName: phaseName,
            enrollmentId: enrollmentId
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Program context header
                    programContextHeader

                    // Progress header
                    WorkoutProgressHeader(
                        elapsedTimeDisplay: viewModel.elapsedTimeDisplay,
                        progressText: viewModel.progressText,
                        completedCount: viewModel.completedCount,
                        totalExercises: viewModel.totalExercises,
                        progressPercentage: viewModel.progressPercentage,
                        isTimerVisible: $viewModel.isTimerVisible
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Main content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Exercise list
                            exerciseListSection

                            // Current exercise detail
                            if let exercise = viewModel.currentExercise {
                                currentExerciseSection(exercise: exercise)
                            }
                        }
                        .padding()
                    }

                    // Bottom action bar
                    bottomActionBar
                }

                // Rest timer overlay
                if viewModel.showRestTimer {
                    RestTimerOverlay(
                        timeRemaining: viewModel.restTimeRemaining,
                        totalTime: viewModel.restTotalTime,
                        onSkip: {
                            viewModel.skipRestTimer()
                            viewModel.moveToNextExercise()
                        }
                    )
                }

                // Loading overlay
                if viewModel.isLoading {
                    ProgramLoadingOverlay("Saving exercise...")
                }
            }
            .navigationTitle(viewModel.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        HapticFeedback.light()
                        showExitConfirmation = true
                    }
                }
            }
            .confirmationDialog("Exit Workout?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
                Button("Save & Exit", role: .destructive) {
                    Task {
                        await viewModel.completeWorkout()
                        dismiss()
                    }
                }
                Button("Exit Without Saving", role: .destructive) {
                    viewModel.stopTimer()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your completed exercises will be saved if you choose 'Save & Exit'.")
            }
            .sheet(isPresented: $showCompletionSheet) {
                WorkoutCompletionView(
                    workoutName: viewModel.workoutName,
                    elapsedTimeDisplay: viewModel.elapsedTimeDisplay,
                    completedCount: viewModel.completedCount,
                    totalExercises: viewModel.totalExercises,
                    volumeDisplay: viewModel.volumeDisplay,
                    averageRPE: viewModel.averageRPE,
                    averagePain: viewModel.averagePain,
                    onDismiss: {
                        dismiss()
                    }
                )
            }
            .onChange(of: viewModel.isWorkoutCompleted) { _, isCompleted in
                if isCompleted {
                    showCompletionSheet = true
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onAppear {
                viewModel.startTimer()
            }
            .onDisappear {
                viewModel.stopTimer()
            }
        }
    }

    // MARK: - Program Context Header

    private var programContextHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text(viewModel.headerSubtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Program: \(viewModel.headerSubtitle)")
    }

    // MARK: - Exercise List Section

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.exercises.isEmpty {
                ProgramEmptyStateView.noExercises()
            } else {
                ForEach(viewModel.exercises) { exercise in
                    ExerciseListRow(
                        exercise: exercise,
                        isCompleted: viewModel.isExerciseCompleted(exercise),
                        isSkipped: viewModel.isExerciseSkipped(exercise),
                        isCurrent: viewModel.isCurrentExercise(exercise),
                        exerciseNumber: (viewModel.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0) + 1,
                        totalExercises: viewModel.totalExercises,
                        onTap: {
                            if !viewModel.isExerciseCompleted(exercise) && !viewModel.isExerciseSkipped(exercise) {
                                viewModel.selectExercise(exercise)
                            }
                        }
                    )
                }
            }
        }
        .accessibilityLabel("Exercise list, \(viewModel.completedCount) of \(viewModel.totalExercises) completed")
    }

    // MARK: - Current Exercise Section

    private func currentExerciseSection(exercise: ManualSessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Current Exercise")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.totalExercises)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current exercise: \(viewModel.currentExerciseIndex + 1) of \(viewModel.totalExercises)")

            // Exercise details card
            VStack(alignment: .leading, spacing: 16) {
                // Exercise name and target
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.exerciseName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    // Target prescription
                    HStack(spacing: 16) {
                        targetPill(icon: "number", value: "\(exercise.targetSets ?? 0) sets")
                        targetPill(icon: "arrow.counterclockwise", value: "\(exercise.targetReps ?? "0") reps")
                        if let load = exercise.targetLoad, load > 0 {
                            targetPill(icon: "scalemass", value: "\(Int(load)) \(exercise.loadUnit ?? "lbs")")
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Target: \(exercise.targetSets ?? 0) sets of \(exercise.targetReps ?? "0") reps\(exercise.targetLoad.map { $0 > 0 ? " at \(Int($0)) \(exercise.loadUnit ?? "lbs")" : "" } ?? "")")
                }

                Divider()

                // Set logging
                VStack(alignment: .leading, spacing: 12) {
                    Text("Log Your Sets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(0..<viewModel.actualSets, id: \.self) { setIndex in
                        GestureSetRow(
                            setNumber: setIndex + 1,
                            reps: Binding(
                                get: { viewModel.repsPerSet[safe: setIndex] ?? 10 },
                                set: { newValue in
                                    if setIndex < viewModel.repsPerSet.count {
                                        viewModel.repsPerSet[setIndex] = newValue
                                    }
                                }
                            ),
                            weight: Binding(
                                get: { viewModel.weightPerSet[safe: setIndex] ?? 0 },
                                set: { newValue in
                                    if setIndex < viewModel.weightPerSet.count {
                                        viewModel.weightPerSet[setIndex] = newValue
                                    }
                                }
                            ),
                            prescribedReps: Int(exercise.targetReps ?? "10") ?? 10,
                            prescribedWeight: exercise.targetLoad ?? 0,
                            loadUnit: viewModel.loadUnit
                        )
                        .accessibilityLabel("Set \(setIndex + 1): \(viewModel.repsPerSet[safe: setIndex] ?? 10) reps at \(Int(viewModel.weightPerSet[safe: setIndex] ?? 0)) \(viewModel.loadUnit)")
                    }
                }

                Divider()

                // RPE and Pain feedback
                feedbackSection

                // Optional notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                        .accessibilityLabel("Exercise notes")
                        .accessibilityHint("Optional notes about this exercise")
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .accessibilityElement(children: .contain)
    }

    private func targetPill(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }

    private var feedbackSection: some View {
        VStack(spacing: 16) {
            // RPE slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RPE (Effort)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(viewModel.rpe))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rpeColor(Int(viewModel.rpe)))
                }

                Slider(value: $viewModel.rpe, in: 1...10, step: 1)
                    .tint(rpeColor(Int(viewModel.rpe)))
                    .accessibilityLabel("RPE Effort level")
                    .accessibilityValue("\(Int(viewModel.rpe)) out of 10")
                    .accessibilityHint("1 is easy, 10 is max effort")

                HStack {
                    Text("Easy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Max Effort")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityHidden(true)
            }

            // Pain slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pain Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(viewModel.painScore))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(painColor(Int(viewModel.painScore)))
                }

                Slider(value: $viewModel.painScore, in: 0...10, step: 1)
                    .tint(painColor(Int(viewModel.painScore)))
                    .accessibilityLabel("Pain level")
                    .accessibilityValue("\(Int(viewModel.painScore)) out of 10")
                    .accessibilityHint("0 is no pain, 10 is severe pain")

                HStack {
                    Text("No Pain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Severe")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            // Main action buttons
            HStack(spacing: 12) {
                // Skip button
                Button {
                    HapticFeedback.light()
                    viewModel.skipCurrentExercise()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.currentExercise == nil)
                .accessibilityLabel("Skip exercise")
                .accessibilityHint("Skips the current exercise and moves to the next one")

                // Complete button
                Button {
                    Task {
                        await viewModel.completeCurrentExercise()
                    }
                } label: {
                    Label("Complete Exercise", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentExercise == nil || viewModel.isLoading)
                .accessibilityLabel("Complete exercise")
                .accessibilityHint("Saves your logged sets and marks exercise as complete")
            }

            // Quick complete option
            if viewModel.currentExercise != nil {
                Button {
                    Task {
                        await viewModel.quickCompleteExercise()
                    }
                } label: {
                    Text("Quick Complete (Prescribed Values)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Quick complete with prescribed values")
                .accessibilityHint("Completes exercise using the target sets and reps")
            }

            // Finish workout button (when exercises are done)
            if viewModel.canCompleteWorkout {
                Button {
                    Task {
                        await viewModel.completeWorkout()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.allExercisesCompleted ? "flag.checkered" : "flag")
                        Text(viewModel.allExercisesCompleted ? "Finish Workout" : "Finish Early")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.allExercisesCompleted ? .green : .orange)
                .disabled(viewModel.isLoading)
                .accessibilityLabel(viewModel.allExercisesCompleted ? "Finish workout" : "Finish workout early")
                .accessibilityHint("Saves your workout and shows completion summary")
                .accessibilityValue("\(viewModel.completedCount) of \(viewModel.totalExercises) exercises completed")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
    }

    // MARK: - Helper Colors

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...4: return .green
        case 5...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private func painColor(_ value: Int) -> Color {
        switch value {
        case 0...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

// MARK: - Exercise List Row

private struct ExerciseListRow: View {
    let exercise: ManualSessionExercise
    let isCompleted: Bool
    let isSkipped: Bool
    let isCurrent: Bool
    let exerciseNumber: Int
    let totalExercises: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else if isSkipped {
                        Image(systemName: "forward.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("\(exerciseNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(isCurrent ? .blue : .secondary)
                    }
                }

                // Exercise info
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(.subheadline)
                        .fontWeight(isCurrent ? .semibold : .regular)
                        .foregroundColor(isSkipped ? .secondary : .primary)
                        .strikethrough(isSkipped)

                    Text(exercise.setsRepsDisplay + (exercise.targetLoad.map { " @ \(Int($0)) \(exercise.loadUnit ?? "lbs")" } ?? ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                if isCurrent && !isCompleted && !isSkipped {
                    Text("CURRENT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .background(isCurrent ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCurrent ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted || isSkipped)
        .accessibilityLabel("\(exercise.exerciseName), \(exercise.setsRepsDisplay)\(isCompleted ? ", completed" : isSkipped ? ", skipped" : isCurrent ? ", current exercise" : "")")
        .accessibilityHint(isCompleted || isSkipped ? "" : "Double tap to select this exercise")
    }

    private var statusColor: Color {
        if isCompleted { return .green }
        if isSkipped { return .orange }
        if isCurrent { return .blue }
        return .gray
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramWorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramWorkoutExecutionView(
            session: ManualSession(
                id: UUID(),
                patientId: UUID(),
                name: "Upper Body Strength",
                sessionSource: .program
            ),
            exercises: [
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseName: "Bench Press",
                    sequence: 0,
                    targetSets: 3,
                    targetReps: "10",
                    targetLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseName: "Dumbbell Row",
                    sequence: 1,
                    targetSets: 3,
                    targetReps: "12",
                    targetLoad: 50,
                    loadUnit: "lbs",
                    restPeriodSeconds: 60
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseName: "Shoulder Press",
                    sequence: 2,
                    targetSets: 3,
                    targetReps: "10",
                    targetLoad: 45,
                    loadUnit: "lbs",
                    restPeriodSeconds: 60
                )
            ],
            patientId: UUID(),
            programName: "12-Week Strength",
            phaseName: "Phase 1: Foundation"
        )
    }
}
#endif
