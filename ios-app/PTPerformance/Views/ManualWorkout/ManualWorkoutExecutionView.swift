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
        session.name
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
    var exercisesByBlock: [(blockType: String, exercises: [ManualSessionExercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.blockType ?? "General" }
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value.sorted { $0.sequence < $1.sequence }) }
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
        actualSets = exercise.prescribedSets
        repsPerSet = Array(repeating: Int(exercise.prescribedReps ?? "10") ?? 10, count: exercise.prescribedSets)
        actualLoad = exercise.prescribedLoad != nil ? String(format: "%.0f", exercise.prescribedLoad!) : ""
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

    init(session: ManualSession, exercises: [ManualSessionExercise], patientId: UUID) {
        _viewModel = StateObject(wrappedValue: ManualWorkoutExecutionViewModel(
            session: session,
            exercises: exercises,
            patientId: patientId
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isWorkoutCompleted {
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
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
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
            Text("Workout Blocks")
                .font(.headline)

            ForEach(viewModel.exercisesByBlock, id: \.blockType) { block in
                blockRow(blockType: block.blockType, exercises: block.exercises)
            }
        }
    }

    private func blockRow(blockType: String, exercises: [ManualSessionExercise]) -> some View {
        let isCompleted = viewModel.isBlockCompleted(blockType)
        let isCurrent = viewModel.isCurrentBlock(blockType)
        let blockTypeEnum = WorkoutBlockType(rawValue: blockType.lowercased().replacingOccurrences(of: " ", with: "_"))

        return DisclosureGroup {
            VStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .padding(.leading, 8)
        } label: {
            HStack {
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
        }
        .padding(12)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }

    private func exerciseRow(_ exercise: ManualSessionExercise) -> some View {
        let isCompleted = viewModel.completedExerciseIds.contains(exercise.id)
        let isSkipped = viewModel.skippedExerciseIds.contains(exercise.id)
        let isCurrent = viewModel.currentExercise?.id == exercise.id

        return Button {
            if !isCompleted && !isSkipped {
                viewModel.selectExercise(exercise)
            }
        } label: {
            HStack {
                // Status Icon
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isSkipped {
                    Image(systemName: "forward.fill")
                        .foregroundColor(.orange)
                } else if isCurrent {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }

                // Exercise Name
                Text(exercise.exerciseName ?? "Exercise")
                    .font(.subheadline)
                    .foregroundColor(isCompleted || isSkipped ? .secondary : .primary)
                    .strikethrough(isSkipped)

                Spacer()

                // Prescription Summary
                Text("\(exercise.prescribedSets) x \(exercise.prescribedReps ?? "10")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .disabled(isCompleted || isSkipped)
    }

    // MARK: - Current Exercise Card

    private func currentExerciseCard(_ exercise: ManualSessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Exercise")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(exercise.exerciseName ?? "Exercise")
                    .font(.title2)
                    .fontWeight(.bold)

                // Target prescription
                HStack(spacing: 16) {
                    Label("\(exercise.prescribedSets) sets", systemImage: "number")
                    Label("\(exercise.prescribedReps ?? "10") reps", systemImage: "repeat")
                    if let load = exercise.prescribedLoad, let unit = exercise.loadUnit {
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
        ManualWorkoutExecutionView(
            session: ManualSession(
                id: UUID(),
                patientId: UUID(),
                templateId: nil,
                name: "Upper Body Strength",
                notes: nil,
                startedAt: Date(),
                completedAt: nil,
                durationMinutes: nil,
                totalVolume: nil,
                avgRpe: nil,
                avgPain: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            exercises: [
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: UUID(),
                    blockType: "push",
                    sequence: 1,
                    prescribedSets: 3,
                    prescribedReps: "10",
                    prescribedLoad: 135,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    actualSets: nil,
                    actualReps: nil,
                    actualLoad: nil,
                    rpe: nil,
                    painScore: nil,
                    notes: nil,
                    completed: false,
                    createdAt: Date(),
                    exerciseTemplates: Exercise.ExerciseTemplate(
                        id: UUID(),
                        name: "Bench Press",
                        category: "push",
                        body_region: "upper",
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        videoDuration: nil,
                        formCues: nil,
                        techniqueCues: nil,
                        commonMistakes: nil,
                        safetyNotes: nil
                    )
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: UUID(),
                    blockType: "push",
                    sequence: 2,
                    prescribedSets: 3,
                    prescribedReps: "12",
                    prescribedLoad: 30,
                    loadUnit: "lbs",
                    restPeriodSeconds: 60,
                    actualSets: nil,
                    actualReps: nil,
                    actualLoad: nil,
                    rpe: nil,
                    painScore: nil,
                    notes: nil,
                    completed: false,
                    createdAt: Date(),
                    exerciseTemplates: Exercise.ExerciseTemplate(
                        id: UUID(),
                        name: "Dumbbell Shoulder Press",
                        category: "push",
                        body_region: "upper",
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        videoDuration: nil,
                        formCues: nil,
                        techniqueCues: nil,
                        commonMistakes: nil,
                        safetyNotes: nil
                    )
                ),
                ManualSessionExercise(
                    id: UUID(),
                    manualSessionId: UUID(),
                    exerciseTemplateId: UUID(),
                    blockType: "pull",
                    sequence: 3,
                    prescribedSets: 4,
                    prescribedReps: "8",
                    prescribedLoad: 100,
                    loadUnit: "lbs",
                    restPeriodSeconds: 90,
                    actualSets: nil,
                    actualReps: nil,
                    actualLoad: nil,
                    rpe: nil,
                    painScore: nil,
                    notes: nil,
                    completed: false,
                    createdAt: Date(),
                    exerciseTemplates: Exercise.ExerciseTemplate(
                        id: UUID(),
                        name: "Barbell Row",
                        category: "pull",
                        body_region: "upper",
                        videoUrl: nil,
                        videoThumbnailUrl: nil,
                        videoDuration: nil,
                        formCues: nil,
                        techniqueCues: nil,
                        commonMistakes: nil,
                        safetyNotes: nil
                    )
                )
            ],
            patientId: UUID()
        )
    }
}
#endif
