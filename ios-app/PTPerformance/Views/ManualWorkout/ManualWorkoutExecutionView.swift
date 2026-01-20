//
//  ManualWorkoutExecutionView.swift
//  PTPerformance
//
//  View for executing manual workouts with block-based navigation and exercise logging
//

import SwiftUI
import Combine

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
    private let patientId: UUID
    private var timerCancellable: AnyCancellable?
    private var startTime: Date?

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
            .map { ($0.key, $0.value.sorted { $0.sequence < $1.sequence }) }
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
            // Log the exercise
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

            completedExerciseIds.insert(exercise.id)

            DebugLogger.shared.success("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName ?? "Unknown")' completed")

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
        DebugLogger.shared.info("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName ?? "Unknown")' skipped")

        moveToNextExercise()
    }

    // BUILD 216: Skip a specific exercise (not just current)
    func skipExercise(_ exercise: ManualSessionExercise) {
        skippedExerciseIds.insert(exercise.id)
        DebugLogger.shared.info("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName ?? "Unknown")' skipped")

        // If this was the current exercise, move to next
        if currentExercise?.id == exercise.id {
            moveToNextExercise()
        }
    }

    // BUILD 216: Quick complete exercise with prescribed values
    func quickCompleteExercise(_ exercise: ManualSessionExercise) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use prescribed values for quick completion
            let sets = exercise.targetSets ?? 3
            let repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: sets)
            let load = exercise.targetLoad

            try await service.logManualExercise(
                manualSessionExerciseId: exercise.id,
                patientId: patientId,
                actualSets: sets,
                actualReps: repsPerSet,
                actualLoad: load,
                loadUnit: exercise.loadUnit ?? "lbs",
                rpe: 5,  // Default RPE for quick complete
                painScore: 0,  // Default no pain for quick complete
                notes: nil
            )

            completedExerciseIds.insert(exercise.id)

            DebugLogger.shared.success("MANUAL_WORKOUT", "Exercise '\(exercise.exerciseName ?? "Unknown")' quick completed")

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
            _ = try await service.completeWorkout(
                session.id,
                totalVolume: totalVolume,
                avgRpe: averageRPE,
                avgPain: averagePain,
                durationMinutes: durationMinutes
            )

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
}

// MARK: - Main View

/// View for executing manual workouts with exercise logging
struct ManualWorkoutExecutionView: View {
    @StateObject private var viewModel: ManualWorkoutExecutionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEndEarlyConfirmation = false
    @State private var expandedExercises: Set<UUID> = []  // BUILD 216: Track expanded exercises
    let onComplete: (() -> Void)?

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
            .onChange(of: viewModel.isWorkoutCompleted) { isCompleted in
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
                            withAnimation {
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
                        withAnimation {
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
            // Exercise Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Exercise")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Use notes as display name if exercise name is just a number (strength block)
                let currentDisplayName = {
                    let name = exercise.exerciseName ?? "Exercise"
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
