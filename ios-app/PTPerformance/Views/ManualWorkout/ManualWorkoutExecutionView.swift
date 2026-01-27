//
//  ManualWorkoutExecutionView.swift
//  PTPerformance
//
//  View for executing manual workouts with block-based navigation and exercise logging
//

import SwiftUI
import Combine

// MARK: - BUILD 260: Local Exercise Template for Picker

/// Local struct for exercise templates used in the picker (Identifiable with UUID)
struct PickerExerciseTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let bodyRegion: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case bodyRegion = "body_region"
    }
}

// MARK: - View Model

/// View Model for managing manual workout execution state and logic
@MainActor
class ManualWorkoutExecutionViewModel: ObservableObject {
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

    // Current exercise input fields
    @Published var actualSets: Int = 0
    @Published var repsPerSet: [Int] = []
    @Published var actualLoad: String = ""
    @Published var loadUnit: String = "lbs"
    @Published var rpe: Double = 5.0
    @Published var painScore: Double = 0.0
    @Published var notes: String = ""

    // Exercise completion tracking
    @Published var completedExerciseIds: Set<UUID> = []
    @Published var skippedExerciseIds: Set<UUID> = []

    // MARK: - Private Properties

    private let service: ManualWorkoutService
    let patientId: UUID  // BUILD 260: Made internal for exercise picker
    private var timerCancellable: AnyCancellable?
    private var startTime: Date?

    // BUILD 258: Support for prescribed sessions
    private var isPrescribedSession: Bool = false
    private var prescribedSessionId: UUID?
    private var prescribedExerciseIdMap: [UUID: UUID] = [:]  // ManualSessionExercise.id -> session_exercise_id

    // MARK: - Computed Properties

    var workoutName: String {
        session.name ?? "Workout"
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
        // Can complete when all exercises are done or user chooses to end early
        completedCount == totalExercises || completedCount > 0
    }

    var allExercisesCompleted: Bool {
        completedCount == totalExercises
    }

    /// Group exercises by block type for block-based navigation
    /// BUILD 220: Sort by proper workout order (warm-up first, recovery last)
    var exercisesByBlock: [(blockType: String, exercises: [ManualSessionExercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.blockType ?? "General" }
        // Sort by workout block order, not alphabetically
        return grouped.sorted { WorkoutBlockType.sortOrder(for: $0.key) < WorkoutBlockType.sortOrder(for: $1.key) }
            .map { ($0.key, $0.value.sorted { ($0.sequence, $0.id.uuidString) < ($1.sequence, $1.id.uuidString) }) }
    }

    /// Check if a block is completed
    func isBlockCompleted(_ blockType: String) -> Bool {
        let blockExercises = exercises.filter { ($0.blockType ?? "General") == blockType }
        return blockExercises.allSatisfy { completedExerciseIds.contains($0.id) || skippedExerciseIds.contains($0.id) }
    }

    /// Check if a block is current (has at least one incomplete exercise and previous blocks are complete)
    func isCurrentBlock(_ blockType: String) -> Bool {
        let blocks = exercisesByBlock
        guard let blockIndex = blocks.firstIndex(where: { $0.blockType == blockType }) else { return false }

        // Check all previous blocks are completed
        for i in 0..<blockIndex {
            if !isBlockCompleted(blocks[i].blockType) {
                return false
            }
        }

        // This block should have at least one incomplete exercise
        return !isBlockCompleted(blockType)
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
        return Double(totalRPE) / Double(completedWithRPE.count)
    }

    var averagePain: Double? {
        let completedWithPain = exercises.filter { completedExerciseIds.contains($0.id) && $0.painScore != nil }
        guard !completedWithPain.isEmpty else { return nil }
        let totalPain = completedWithPain.compactMap { $0.painScore }.reduce(0, +)
        return Double(totalPain) / Double(completedWithPain.count)
    }

    // MARK: - Initialization

    init(session: ManualSession, exercises: [ManualSessionExercise], patientId: UUID, service: ManualWorkoutService = ManualWorkoutService()) {
        self.session = session
        self.exercises = exercises.sorted { $0.sequence < $1.sequence }
        self.patientId = patientId
        self.service = service
        self.isPrescribedSession = false

        // Initialize with first exercise defaults
        if let firstExercise = self.exercises.first {
            setupInputFields(for: firstExercise)
        }
    }

    /// BUILD 258: Initialize from a prescribed Session with Exercise array
    init(prescribedSession: Session, exercises: [Exercise], patientId: UUID, service: ManualWorkoutService = ManualWorkoutService()) {
        // Create a wrapper ManualSession from the prescribed Session
        self.session = ManualSession(
            id: prescribedSession.id,
            patientId: patientId,
            name: prescribedSession.name,
            notes: prescribedSession.notes,
            sourceTemplateId: nil,
            sourceTemplateType: nil,
            startedAt: Date(),
            completedAt: nil,
            completed: false,
            totalVolume: nil,
            avgRpe: nil,
            avgPain: nil,
            durationMinutes: nil,
            createdAt: Date()
        )

        // Convert Exercise to ManualSessionExercise and track mapping
        var exerciseMap: [UUID: UUID] = [:]
        self.exercises = exercises.enumerated().map { index, exercise in
            let manualExerciseId = UUID()
            exerciseMap[manualExerciseId] = exercise.id  // Map to original session_exercise_id
            return ManualSessionExercise(
                id: manualExerciseId,
                manualSessionId: prescribedSession.id,
                exerciseTemplateId: exercise.exercise_template_id,
                exerciseName: exercise.exercise_name ?? "Exercise",
                blockName: exercise.movement_pattern,
                sequence: exercise.sequence ?? index,
                targetSets: exercise.prescribed_sets,
                targetReps: exercise.prescribed_reps,
                targetLoad: exercise.prescribed_load,
                loadUnit: exercise.load_unit,
                restPeriodSeconds: exercise.rest_period_seconds,
                notes: exercise.notes,
                createdAt: Date()
            )
        }.sorted { $0.sequence < $1.sequence }

        self.patientId = patientId
        self.service = service
        self.isPrescribedSession = true
        self.prescribedSessionId = prescribedSession.id
        self.prescribedExerciseIdMap = exerciseMap

        // Initialize with first exercise defaults
        if let firstExercise = self.exercises.first {
            setupInputFields(for: firstExercise)
        }
    }

    // MARK: - Load Exercises (for when initialized without exercises)

    @Published var needsExerciseLoad = false

    func loadExercisesIfNeeded() async {
        guard exercises.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            DebugLogger.shared.log("📥 Loading exercises for session: \(session.id)", level: .diagnostic)

            let loadedExercises = try await service.fetchSessionExercises(sessionId: session.id)

            await MainActor.run {
                exercises = loadedExercises
                if let firstExercise = exercises.first {
                    setupInputFields(for: firstExercise)
                }
                DebugLogger.shared.log("✅ Loaded \(exercises.count) exercises", level: .success)
            }
        } catch {
            DebugLogger.shared.log("❌ Failed to load exercises: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load exercises: \(error.localizedDescription)"
            showError = true
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

    // MARK: - Exercise Navigation

    func setupInputFields(for exercise: ManualSessionExercise) {
        actualSets = exercise.targetSets ?? 3
        repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: exercise.targetSets ?? 3)
        actualLoad = exercise.targetLoad != nil ? String(format: "%.0f", exercise.targetLoad!) : ""
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

    // MARK: - Exercise Actions

    func completeCurrentExercise() async {
        guard let exercise = currentExercise else { return }

        isLoading = true
        errorMessage = nil

        do {
            // BUILD 258: Log to appropriate table based on session type
            if isPrescribedSession, let originalId = prescribedExerciseIdMap[exercise.id] {
                // Log to exercise_logs with session_exercise_id
                try await service.logPrescribedExercise(
                    sessionExerciseId: originalId,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: Array(repsPerSet.prefix(actualSets)),
                    actualLoad: Double(actualLoad),
                    loadUnit: loadUnit,
                    rpe: Int(rpe),
                    painScore: Int(painScore),
                    notes: notes.isEmpty ? nil : notes
                )
            } else {
                // Log to exercise_logs with manual_session_exercise_id
                try await service.logManualExercise(
                    manualSessionExerciseId: exercise.id,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: Array(repsPerSet.prefix(actualSets)),
                    actualLoad: Double(actualLoad),
                    loadUnit: loadUnit,
                    rpe: Int(rpe),
                    painScore: Int(painScore),
                    notes: notes.isEmpty ? nil : notes
                )
            }

            completedExerciseIds.insert(exercise.id)

            DebugLogger.shared.success("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName)' completed")

            isLoading = false
            moveToNextExercise()

        } catch {
            DebugLogger.shared.error("MANUAL_WORKOUT", "Failed to complete exercise: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }

    func skipCurrentExercise() {
        guard let exercise = currentExercise else { return }

        skippedExerciseIds.insert(exercise.id)
        DebugLogger.shared.info("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName)' skipped")

        moveToNextExercise()
    }

    // BUILD 216: Skip a specific exercise (not just current)
    func skipExercise(_ exercise: ManualSessionExercise) {
        skippedExerciseIds.insert(exercise.id)
        DebugLogger.shared.info("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName)' skipped")

        // If this was the current exercise, move to next
        if currentExercise?.id == exercise.id {
            moveToNextExercise()
        }
    }

    // BUILD 216: Quick complete exercise with prescribed values
    // BUILD 258: Updated to support both prescribed and manual sessions
    func quickCompleteExercise(_ exercise: ManualSessionExercise) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use prescribed values for quick completion
            let sets = exercise.targetSets ?? 3
            let repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: sets)
            let load = exercise.targetLoad

            // BUILD 258: Log to appropriate table based on session type
            if isPrescribedSession, let originalId = prescribedExerciseIdMap[exercise.id] {
                try await service.logPrescribedExercise(
                    sessionExerciseId: originalId,
                    patientId: patientId,
                    actualSets: sets,
                    actualReps: repsPerSet,
                    actualLoad: load,
                    loadUnit: exercise.loadUnit ?? "lbs",
                    rpe: 5,
                    painScore: 0,
                    notes: nil
                )
            } else {
                try await service.logManualExercise(
                    manualSessionExerciseId: exercise.id,
                    patientId: patientId,
                    actualSets: sets,
                    actualReps: repsPerSet,
                    actualLoad: load,
                    loadUnit: exercise.loadUnit ?? "lbs",
                    rpe: 5,
                    painScore: 0,
                    notes: nil
                )
            }

            completedExerciseIds.insert(exercise.id)

            DebugLogger.shared.success("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName)' quick completed")

            isLoading = false

            // If this was the current exercise, move to next
            if currentExercise?.id == exercise.id {
                moveToNextExercise()
            }

            // Check if all exercises done
            if allExercisesCompleted {
                showCompletionConfirmation = true
            }

        } catch {
            DebugLogger.shared.error("MANUAL_WORKOUT", "Failed to quick complete exercise: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }

    func completeWorkout() async {
        isLoading = true
        errorMessage = nil
        stopTimer()

        let durationMinutes = Int(elapsedTime / 60)

        do {
            // BUILD 265: Use different completion method based on session type
            if isPrescribedSession, let prescribedId = prescribedSessionId {
                // Prescribed sessions are in the sessions table
                try await service.completePrescribedSession(
                    prescribedId,
                    totalVolume: totalVolume,
                    avgRpe: averageRPE,
                    avgPain: averagePain,
                    durationMinutes: durationMinutes
                )
            } else {
                // Manual sessions are in the manual_sessions table
                _ = try await service.completeWorkout(
                    session.id,
                    totalVolume: totalVolume,
                    avgRpe: averageRPE,
                    avgPain: averagePain,
                    durationMinutes: durationMinutes
                )
            }

            DebugLogger.shared.success("MANUAL_WORKOUT", """
                Workout completed:
                Duration: \(durationMinutes) minutes
                Volume: \(Int(totalVolume)) lbs
                Exercises: \(completedCount)/\(totalExercises)
                """)

            isLoading = false
            isWorkoutCompleted = true

        } catch {
            DebugLogger.shared.error("MANUAL_WORKOUT", "Failed to complete workout: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }

    // MARK: - Reps Array Management

    func updateSetsCount(_ newCount: Int) {
        let previousCount = repsPerSet.count
        if newCount > previousCount {
            // Add more sets with default reps
            let defaultReps = repsPerSet.last ?? 10
            repsPerSet.append(contentsOf: Array(repeating: defaultReps, count: newCount - previousCount))
        } else if newCount < previousCount {
            repsPerSet = Array(repsPerSet.prefix(newCount))
        }
        actualSets = newCount
    }

    // MARK: - BUILD 260: Exercise Management

    /// Replace an exercise with a substitute
    func replaceExercise(_ oldExercise: ManualSessionExercise, with newExercise: ManualSessionExercise) {
        if let index = exercises.firstIndex(where: { $0.id == oldExercise.id }) {
            exercises[index] = newExercise
            DebugLogger.shared.log("🔄 Replaced exercise \(oldExercise.exerciseName) with \(newExercise.exerciseName)", level: .success)
        }
    }

    /// Add an exercise from a template
    func addExerciseFromTemplate(_ template: PickerExerciseTemplate) {
        let newExercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: session.id,
            exerciseTemplateId: template.id,
            exerciseName: template.name,
            blockName: template.category,
            sequence: exercises.count,
            targetSets: 3,
            targetReps: "10",
            targetLoad: nil,
            loadUnit: "lbs",
            restPeriodSeconds: 90,
            notes: nil,
            createdAt: Date()
        )
        exercises.append(newExercise)
        DebugLogger.shared.log("➕ Added exercise: \(template.name)", level: .success)
    }
}

// MARK: - Main View

/// View for executing manual workouts with exercise logging
struct ManualWorkoutExecutionView: View {
    @StateObject private var viewModel: ManualWorkoutExecutionViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabase: PTSupabaseClient  // BUILD 261: For exercise picker sheet
    @State private var showEndEarlyConfirmation = false
    @State private var expandedExercises: Set<UUID> = []  // BUILD 216: Track expanded exercises
    let onComplete: (() -> Void)?

    // BUILD 260: Exercise detail, AI substitution, and add exercise
    @State private var showExerciseDetail = false
    @State private var selectedExerciseForDetail: ManualSessionExercise?
    @State private var showAISubstitution = false
    @State private var selectedExerciseForSubstitution: ManualSessionExercise?
    @State private var showAddExercise = false

    init(session: ManualSession, exercises: [ManualSessionExercise], patientId: UUID, onComplete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ManualWorkoutExecutionViewModel(
            session: session,
            exercises: exercises,
            patientId: patientId
        ))
        self.onComplete = onComplete
    }

    /// Convenience initializer that creates a view with empty exercises
    /// The ViewModel should fetch exercises when this is used
    init(session: ManualSession, patientId: UUID, onComplete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ManualWorkoutExecutionViewModel(
            session: session,
            exercises: [],  // Will be loaded by ViewModel
            patientId: patientId
        ))
        self.onComplete = onComplete
    }

    /// BUILD 258: Initialize from a prescribed Session for unified workout execution
    init(prescribedSession: Session, exercises: [Exercise], patientId: UUID, onComplete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ManualWorkoutExecutionViewModel(
            prescribedSession: prescribedSession,
            exercises: exercises,
            patientId: patientId
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    // Loading exercises state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading workout...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.isWorkoutCompleted {
                    workoutCompletedView
                } else {
                    workoutExecutionView
                }
            }
            .navigationTitle(viewModel.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        if viewModel.completedCount > 0 {
                            showEndEarlyConfirmation = true
                        } else {
                            onComplete?()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .task {
                DebugLogger.shared.log("🏋️ ManualWorkoutExecutionView task started", level: .diagnostic)
                DebugLogger.shared.log("🏋️ Session ID: \(viewModel.session.id)", level: .diagnostic)
                DebugLogger.shared.log("🏋️ Initial exercise count: \(viewModel.exercises.count)", level: .diagnostic)

                // Load exercises if needed (for convenience init)
                await viewModel.loadExercisesIfNeeded()

                DebugLogger.shared.log("🏋️ After load, exercise count: \(viewModel.exercises.count)", level: .diagnostic)

                // Start the timer
                viewModel.startTimer()
                DebugLogger.shared.log("🏋️ Timer started", level: .success)
            }
            .onChange(of: viewModel.isWorkoutCompleted) { _, isCompleted in
                // Call onComplete when workout finishes
                if isCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete?()
                    }
                }
            }
            .alert("End Workout Early?", isPresented: $showEndEarlyConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("End Workout", role: .destructive) {
                    Task {
                        await viewModel.completeWorkout()
                    }
                }
            } message: {
                Text("You've completed \(viewModel.completedCount) of \(viewModel.totalExercises) exercises. End workout now?")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Workout Complete!", isPresented: $viewModel.showCompletionConfirmation) {
                Button("Finish") {
                    Task {
                        await viewModel.completeWorkout()
                    }
                }
            } message: {
                Text("Great job! You've completed all exercises.")
            }
            // BUILD 285: Exercise detail sheet with video + technique cues
            .sheet(isPresented: $showExerciseDetail) {
                if let exercise = selectedExerciseForDetail {
                    ExerciseInfoSheet(exercise: exercise)
                        .environmentObject(supabase)
                }
            }
            // BUILD 285: AI substitution sheet with real alternative lookup
            .sheet(isPresented: $showAISubstitution) {
                if let exercise = selectedExerciseForSubstitution {
                    NavigationView {
                        AISubstitutionSheetForManual(
                            exercise: exercise,
                            patientId: viewModel.patientId,
                            onSubstitutionApplied: { newExercise in
                                viewModel.replaceExercise(exercise, with: newExercise)
                                showAISubstitution = false
                            }
                        )
                    }
                    .environmentObject(supabase)
                }
            }
            // BUILD 260: Add exercise sheet
            .sheet(isPresented: $showAddExercise) {
                NavigationView {
                    ExercisePickerForWorkout(
                        onExerciseSelected: { template in
                            viewModel.addExerciseFromTemplate(template)
                            showAddExercise = false
                        }
                    )
                }
                .environmentObject(supabase)  // BUILD 261: Pass environment object to sheet
            }
            .onAppear {
                viewModel.startTimer()
            }
            .onDisappear {
                viewModel.stopTimer()
            }
        }
    }

    // MARK: - Workout Execution View

    @ViewBuilder
    private var workoutExecutionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Header
                progressHeader

                // Block Navigation
                blockNavigationSection

                // Current Exercise Card
                if let exercise = viewModel.currentExercise {
                    currentExerciseCard(exercise)
                }

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Timer and Progress Row
            HStack {
                // Elapsed Time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(viewModel.elapsedTimeDisplay)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }

                Spacer()

                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(viewModel.progressText)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 8)
                        .animation(.easeInOut, value: viewModel.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Block Navigation Section

    private var blockNavigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Exercises")
                .font(.headline)

            // Show all exercises in a flat list with block headers
            ForEach(viewModel.exercisesByBlock, id: \.blockType) { block in
                VStack(spacing: 8) {
                    // Block header
                    blockHeader(blockType: block.blockType, exercises: block.exercises)

                    // All exercises in this block (always visible)
                    ForEach(block.exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
    }

    private func blockHeader(blockType: String, exercises: [ManualSessionExercise]) -> some View {
        let isCompleted = viewModel.isBlockCompleted(blockType)
        let isCurrent = viewModel.isCurrentBlock(blockType)
        let blockTypeEnum = WorkoutBlockType(rawValue: blockType.lowercased().replacingOccurrences(of: " ", with: "_"))

        return HStack {
            Image(systemName: blockTypeEnum?.icon ?? "square.stack.fill")
                .foregroundColor(blockTypeEnum?.color ?? .gray)
                .frame(width: 24)

            Text(blockTypeEnum?.displayName ?? blockType)
                .font(.subheadline)
                .fontWeight(isCurrent ? .semibold : .regular)

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("\(exercises.filter { viewModel.completedExerciseIds.contains($0.id) }.count)/\(exercises.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }

    // BUILD 216: Expandable exercise row with inline completion
    private func exerciseRow(_ exercise: ManualSessionExercise) -> some View {
        let isCompleted = viewModel.completedExerciseIds.contains(exercise.id)
        let isSkipped = viewModel.skippedExerciseIds.contains(exercise.id)
        let isCurrent = viewModel.currentExercise?.id == exercise.id
        let isExpanded = expandedExercises.contains(exercise.id)

        return VStack(spacing: 0) {
            // Header row (always visible)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedExercises.contains(exercise.id) {
                        expandedExercises.remove(exercise.id)
                    } else {
                        expandedExercises.insert(exercise.id)
                        // Also select as current exercise
                        if !isCompleted && !isSkipped {
                            viewModel.selectExercise(exercise)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Status Icon
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    } else if isSkipped {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    } else if isCurrent {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }

                    // Exercise Details
                    VStack(alignment: .leading, spacing: 2) {
                        let displayName = exercise.exerciseName.count <= 2 && Int(exercise.exerciseName) != nil
                            ? (exercise.notes ?? exercise.exerciseName)
                            : exercise.exerciseName

                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(isCurrent ? .semibold : .regular)
                            .foregroundColor(isCompleted || isSkipped ? .secondary : .primary)
                            .strikethrough(isSkipped)
                            .lineLimit(2)

                        // Prescription details
                        HStack(spacing: 8) {
                            Text("\(exercise.targetSets ?? 3) sets")
                                .font(.caption)
                            Text("×")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(exercise.targetReps ?? "10") reps")
                                .font(.caption)
                            if let load = exercise.targetLoad, let unit = exercise.loadUnit {
                                Text("• \(Int(load)) \(unit)")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Chevron for expand/collapse
                    if !isCompleted && !isSkipped {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isCurrent ? Color.blue.opacity(0.08) : Color(.systemBackground))
            }

            // Expanded content
            if isExpanded && !isCompleted && !isSkipped {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 12)

                    // Quick complete button
                    Button {
                        Task {
                            await viewModel.quickCompleteExercise(exercise)
                            _ = withAnimation {
                                expandedExercises.remove(exercise.id)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Complete as Prescribed")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 12)

                    // Or log with details button
                    Button {
                        viewModel.selectExercise(exercise)
                        // Scroll to current exercise card section
                    } label: {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("Log with Custom Values")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 12)

                    // Skip button
                    Button {
                        viewModel.skipExercise(exercise)
                        _ = withAnimation {
                            expandedExercises.remove(exercise.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Exercise")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.blue.opacity(0.3) : Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Current Exercise Card

    private func currentExerciseCard(_ exercise: ManualSessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header with Action Buttons
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Use notes as display name if exercise name is just a number (strength block)
                    let currentDisplayName = {
                        let name = exercise.exerciseName
                        return name.count <= 2 && Int(name) != nil
                            ? (exercise.notes ?? name)
                            : name
                    }()
                    Text(currentDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Target prescription
                    HStack(spacing: 16) {
                        Label("\(exercise.targetSets ?? 3) sets", systemImage: "number")
                        Label("\(exercise.targetReps ?? "10") reps", systemImage: "repeat")
                        if let load = exercise.targetLoad, let unit = exercise.loadUnit {
                            Label("\(Int(load)) \(unit)", systemImage: "scalemass")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // BUILD 260: Action buttons (info, swap, add)
                HStack(spacing: 12) {
                    // Exercise info button
                    Button {
                        selectedExerciseForDetail = exercise
                        showExerciseDetail = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Exercise details")

                    // AI substitute button
                    Button {
                        selectedExerciseForSubstitution = exercise
                        showAISubstitution = true
                    } label: {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .accessibilityLabel("Find substitute")

                    // Add exercise button
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .accessibilityLabel("Add exercise")
                }
            }

            Divider()

            // Sets Completed Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Sets Completed")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Stepper("Sets: \(viewModel.actualSets)", value: Binding(
                    get: { viewModel.actualSets },
                    set: { viewModel.updateSetsCount($0) }
                ), in: 1...10)
                .accessibilityLabel("Sets completed")
                .accessibilityValue("\(viewModel.actualSets) sets")
            }

            // Reps Per Set Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Reps Per Set")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(0..<viewModel.actualSets, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)

                        Spacer()

                        TextField("Reps", value: Binding(
                            get: { viewModel.repsPerSet[safe: index] ?? 0 },
                            set: { newValue in
                                if index < viewModel.repsPerSet.count {
                                    viewModel.repsPerSet[index] = newValue
                                }
                            }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }

            // Load Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight Used")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    TextField("Load", text: $viewModel.actualLoad)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    Picker("Unit", selection: $viewModel.loadUnit) {
                        Text("lbs").tag("lbs")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
            }

            // RPE Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RPE (Rate of Perceived Exertion)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(viewModel.rpe))")
                        .font(.headline)
                        .foregroundColor(rpeColor(Int(viewModel.rpe)))
                }

                Slider(value: $viewModel.rpe, in: 1...10, step: 1)
                    .accentColor(rpeColor(Int(viewModel.rpe)))

                HStack {
                    Text("Easy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Maximum")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Pain Score Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pain Score")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(viewModel.painScore))")
                        .font(.headline)
                        .foregroundColor(painColor(Int(viewModel.painScore)))
                }

                Slider(value: $viewModel.painScore, in: 0...10, step: 1)
                    .accentColor(painColor(Int(viewModel.painScore)))

                HStack {
                    Text("No Pain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Severe")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if Int(viewModel.painScore) > 5 {
                    Label("High pain - Your therapist will be notified", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextEditor(text: $viewModel.notes)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Complete Exercise Button
            Button {
                Task {
                    await viewModel.completeCurrentExercise()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Exercise")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.currentExercise == nil)

            // Skip Exercise Button
            Button {
                viewModel.skipCurrentExercise()
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip Exercise")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(viewModel.currentExercise == nil)

            // Complete Workout Button (visible when all exercises done)
            if viewModel.allExercisesCompleted {
                Button {
                    Task {
                        await viewModel.completeWorkout()
                    }
                } label: {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Complete Workout")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemGray3).opacity(0.9))
            .cornerRadius(16)
        }
    }

    // MARK: - Workout Completed View

    private var workoutCompletedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 40)

                Text("Workout Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(viewModel.workoutName)
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Summary Stats
                VStack(spacing: 16) {
                    summaryStatRow(title: "Duration", value: viewModel.elapsedTimeDisplay, icon: "clock.fill", color: .blue)
                    summaryStatRow(title: "Exercises", value: "\(viewModel.completedCount)/\(viewModel.totalExercises)", icon: "list.bullet", color: .purple)
                    summaryStatRow(title: "Total Volume", value: viewModel.volumeDisplay, icon: "scalemass.fill", color: .green)

                    if let avgRpe = viewModel.averageRPE {
                        summaryStatRow(title: "Avg RPE", value: String(format: "%.1f", avgRpe), icon: "bolt.fill", color: rpeColor(Int(avgRpe)))
                    }

                    if let avgPain = viewModel.averagePain {
                        summaryStatRow(title: "Avg Pain", value: String(format: "%.1f", avgPain), icon: "hand.raised.fill", color: painColor(Int(avgPain)))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 16)
            }
            .padding()
        }
    }

    private func summaryStatRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Color Helpers

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

// MARK: - BUILD 285: Exercise Info Sheet (with video, technique cues, safety notes)

/// Full exercise detail view that fetches template data for video + technique tips
struct ExerciseInfoSheet: View {
    let exercise: ManualSessionExercise
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabase: PTSupabaseClient

    @State private var template: Exercise.ExerciseTemplate?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise Name & Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exerciseName)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            if let block = exercise.blockName {
                                Label(block.capitalized, systemImage: "square.grid.2x2")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                            if let category = template?.category {
                                Label(category.capitalized, systemImage: "tag")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(6)
                            }
                            if let bodyRegion = template?.body_region {
                                Label(bodyRegion.capitalized, systemImage: "figure.arms.open")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                        }
                    }

                    // Video Player
                    if let videoUrl = template?.videoUrl, !videoUrl.isEmpty {
                        VideoPlayerView(videoUrl: videoUrl)
                            .frame(height: 220)
                            .cornerRadius(12)
                    }

                    // Target Prescription
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prescription")
                            .font(.headline)

                        HStack(spacing: 24) {
                            exerciseStatBox(value: "\(exercise.targetSets ?? 3)", label: "Sets")
                            exerciseStatBox(value: exercise.targetReps ?? "10", label: "Reps")
                            if let load = exercise.targetLoad {
                                exerciseStatBox(value: "\(Int(load))", label: exercise.loadUnit ?? "lbs")
                            }
                            if let rest = exercise.restPeriodSeconds {
                                exerciseStatBox(value: "\(rest)s", label: "Rest")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Technique Cues
                    if let cues = template?.techniqueCues,
                       !cues.setup.isEmpty || !cues.execution.isEmpty || !cues.breathing.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Technique Guide")
                                .font(.headline)
                            ExerciseCuesCard(techniqueCues: cues)
                        }
                    }

                    // Form Cues (with video timestamps)
                    if let formCues = template?.formCues, !formCues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Form Cues")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(formCues.enumerated()), id: \.offset) { index, cue in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(index + 1).")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                            .frame(width: 24)

                                        Text(cue.cue)
                                            .font(.subheadline)

                                        Spacer()

                                        if let time = cue.displayTime {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Common Mistakes
                    if let mistakes = template?.commonMistakes, !mistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Common Mistakes", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                                .foregroundColor(.orange)

                            Text(mistakes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(12)
                    }

                    // Safety Notes
                    if let safety = template?.safetyNotes, !safety.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Safety Notes", systemImage: "shield.checkered")
                                .font(.headline)
                                .foregroundColor(.red)

                            Text(safety)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                    }

                    // Exercise Notes
                    if let notes = exercise.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Loading state
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading exercise details...")
                                .font(.caption)
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await fetchTemplateData()
            }
        }
    }

    private func exerciseStatBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 50)
    }

    private func fetchTemplateData() async {
        guard let templateId = exercise.exerciseTemplateId else {
            isLoading = false
            return
        }

        do {
            let response = try await supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region, video_url, video_thumbnail_url, video_duration, form_cues, technique_cues, common_mistakes, safety_notes")
                .eq("id", value: templateId.uuidString)
                .limit(1)
                .execute()

            let templates = try JSONDecoder().decode([Exercise.ExerciseTemplate].self, from: response.data)
            template = templates.first
        } catch {
            DebugLogger.shared.error("EXERCISE_INFO", "Failed to fetch template: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

// MARK: - BUILD 285: AI Substitution Sheet (queries real alternatives)

/// Exercise substitution that queries exercise_templates for same-category alternatives
struct AISubstitutionSheetForManual: View {
    let exercise: ManualSessionExercise
    let patientId: UUID
    let onSubstitutionApplied: (ManualSessionExercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabase: PTSupabaseClient
    @State private var reason = ""
    @State private var alternatives: [PickerExerciseTemplate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlternatives = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find Alternative for:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(exercise.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let block = exercise.blockName {
                        Label(block.capitalized, systemImage: "square.grid.2x2")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !showAlternatives {
                    // Step 1: Reason selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why do you need a substitute?")
                            .font(.headline)

                        VStack(spacing: 12) {
                            substitutionReasonButton(icon: "bandage", text: "Injury / Pain", value: "injury")
                            substitutionReasonButton(icon: "dumbbell", text: "Equipment Unavailable", value: "equipment")
                            substitutionReasonButton(icon: "gauge.with.needle.fill", text: "Too Difficult", value: "difficulty")
                            substitutionReasonButton(icon: "arrow.triangle.swap", text: "Want Variety", value: "variety")
                        }
                    }
                } else {
                    // Step 2: Show alternatives
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Finding alternatives...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if alternatives.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No alternatives found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Try a different reason or add an exercise manually.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Select Alternative")
                                    .font(.headline)
                                Spacer()
                                Text("\(alternatives.count) found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(alternatives) { alt in
                                Button {
                                    applySubstitution(alt)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(alt.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            HStack(spacing: 8) {
                                                if let category = alt.category {
                                                    Text(category.capitalized)
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                                if let region = alt.bodyRegion {
                                                    Text(region.capitalized)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.orange)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }

                        Button {
                            showAlternatives = false
                            alternatives = []
                            reason = ""
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back to reasons")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Find Substitute")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func substitutionReasonButton(icon: String, text: String, value: String) -> some View {
        Button {
            reason = value
            showAlternatives = true
            Task {
                await fetchAlternatives()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.orange)
                Text(text)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func fetchAlternatives() async {
        isLoading = true
        errorMessage = nil

        do {
            // Query exercise_templates for same category, excluding current exercise
            var query = supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region")

            // Filter by same category if available
            if let blockName = exercise.blockName {
                query = query.eq("category", value: blockName.lowercased())
            }

            let response = try await query
                .order("name")
                .limit(30)
                .execute()

            var results = try JSONDecoder().decode([PickerExerciseTemplate].self, from: response.data)

            // Exclude the current exercise by template ID and name
            if let templateId = exercise.exerciseTemplateId {
                results = results.filter { $0.id != templateId }
            }
            results = results.filter { $0.name.lowercased() != exercise.exerciseName.lowercased() }

            alternatives = results
        } catch {
            errorMessage = "Failed to find alternatives"
            DebugLogger.shared.error("SUBSTITUTION", "Failed to fetch alternatives: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func applySubstitution(_ template: PickerExerciseTemplate) {
        let newExercise = ManualSessionExercise(
            id: UUID(),
            manualSessionId: exercise.manualSessionId,
            exerciseTemplateId: template.id,
            exerciseName: template.name,
            blockName: exercise.blockName,
            sequence: exercise.sequence,
            targetSets: exercise.targetSets,
            targetReps: exercise.targetReps,
            targetLoad: exercise.targetLoad,
            loadUnit: exercise.loadUnit,
            restPeriodSeconds: exercise.restPeriodSeconds,
            notes: "Substituted for \(exercise.exerciseName) (\(reason))",
            createdAt: Date()
        )
        onSubstitutionApplied(newExercise)
    }
}

// MARK: - BUILD 285: Exercise Picker with Category Filters

/// Exercise picker with category filter chips and body region badges
struct ExercisePickerForWorkout: View {
    let onExerciseSelected: (PickerExerciseTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var templates: [PickerExerciseTemplate] = []
    @State private var isLoading = false
    @State private var selectedCategory: String? = nil
    @EnvironmentObject var supabase: PTSupabaseClient

    private let categories = ["All", "Push", "Pull", "Hinge", "Squat", "Lunge", "Core", "Cardio", "Mobility"]

    var filteredTemplates: [PickerExerciseTemplate] {
        var results = templates

        if let category = selectedCategory {
            results = results.filter { ($0.category ?? "").localizedCaseInsensitiveContains(category) }
        }

        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return results
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category == "All" ? nil : category
                            }
                        } label: {
                            Text(category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    (selectedCategory == nil && category == "All") || selectedCategory == category
                                    ? Color.blue
                                    : Color(.systemGray5)
                                )
                                .foregroundColor(
                                    (selectedCategory == nil && category == "All") || selectedCategory == category
                                    ? .white
                                    : .primary
                                )
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            if isLoading {
                Spacer()
                ProgressView("Loading exercises...")
                Spacer()
            } else {
                List {
                    Text("\(filteredTemplates.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)

                    ForEach(filteredTemplates) { template in
                        Button {
                            onExerciseSelected(template)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    HStack(spacing: 8) {
                                        if let category = template.category {
                                            Text(category.capitalized)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.7))
                                                .cornerRadius(4)
                                        }
                                        if let region = template.bodyRegion {
                                            Text(region.capitalized)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search exercises")
            }
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .task {
            await loadTemplates()
        }
    }

    private func loadTemplates() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("exercise_templates")
                .select("id, name, category, body_region")
                .order("name")
                .limit(500)
                .execute()

            templates = try JSONDecoder().decode([PickerExerciseTemplate].self, from: response.data)
        } catch {
            DebugLogger.shared.error("EXERCISE_PICKER", "Failed to load templates: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ManualWorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        let sessionId = UUID()
        ManualWorkoutExecutionView(
            session: ManualSession(
                id: sessionId,
                patientId: UUID(),
                name: "Upper Body Strength",
                notes: nil,
                sourceTemplateId: nil,
                sourceTemplateType: nil,
                startedAt: Date(),
                completedAt: nil,
                completed: false,
                totalVolume: nil,
                avgRpe: nil,
                avgPain: nil,
                durationMinutes: nil,
                createdAt: Date()
            ),
            exercises: [
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: sessionId,
                    exerciseTemplateId: UUID(),
                    exerciseName: "Bench Press",
                    blockName: "Push",
                    sequence: 0,
                    targetSets: 3,
                    targetReps: "10",
                    targetLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    notes: nil,
                    createdAt: Date()
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: sessionId,
                    exerciseTemplateId: UUID(),
                    exerciseName: "Dumbbell Shoulder Press",
                    blockName: "Push",
                    sequence: 1,
                    targetSets: 3,
                    targetReps: "12",
                    targetLoad: 30,
                    loadUnit: "lbs",
                    restPeriodSeconds: 60,
                    notes: nil,
                    createdAt: Date()
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: sessionId,
                    exerciseTemplateId: UUID(),
                    exerciseName: "Barbell Row",
                    blockName: "Pull",
                    sequence: 2,
                    targetSets: 4,
                    targetReps: "8",
                    targetLoad: 100,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    notes: nil,
                    createdAt: Date()
                )
            ],
            patientId: UUID()
        )
    }
}
#endif
