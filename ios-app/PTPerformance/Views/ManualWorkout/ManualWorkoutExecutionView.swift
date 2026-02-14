//
//  ManualWorkoutExecutionView.swift
//  PTPerformance
//
//  View for executing manual workouts with block-based navigation and exercise logging
//

import SwiftUI
import Combine

// MARK: - Fatigue Adjustment Model

/// Represents active fatigue-based adjustments for a workout
struct FatigueAdjustment {
    let loadReductionPct: Double   // 0.0 to 1.0 (e.g., 0.3 = 30% reduction)
    let volumeReductionPct: Double // 0.0 to 1.0 (e.g., 0.25 = 25% reduction)
    let reason: String
    let fatigueBand: FatigueBand
    let isDeloadWeek: Bool

    /// Alias for isDeloadWeek for compatibility with task spec
    var isDeload: Bool { isDeloadWeek }

    /// Whether adjustment is active (any reduction applied)
    var isActive: Bool {
        loadReductionPct > 0 || volumeReductionPct > 0
    }

    /// Load reduction as integer percent (for display)
    var loadReductionPercent: Int {
        Int(loadReductionPct * 100)
    }

    /// Volume reduction as integer percent (for display)
    var volumeReductionPercent: Int {
        Int(volumeReductionPct * 100)
    }

    /// Create from fatigue accumulation data
    static func from(fatigue: FatigueAccumulation) -> FatigueAdjustment? {
        switch fatigue.fatigueBand {
        case .critical:
            return FatigueAdjustment(
                loadReductionPct: 0.5,
                volumeReductionPct: 0.4,
                reason: "Critical fatigue detected - significant load and volume reduction for recovery",
                fatigueBand: fatigue.fatigueBand,
                isDeloadWeek: fatigue.deloadRecommended
            )
        case .high:
            return FatigueAdjustment(
                loadReductionPct: 0.3,
                volumeReductionPct: 0.25,
                reason: "High fatigue - reduce intensity and volume for optimal recovery",
                fatigueBand: fatigue.fatigueBand,
                isDeloadWeek: fatigue.deloadRecommended
            )
        case .moderate:
            return FatigueAdjustment(
                loadReductionPct: 0.1,
                volumeReductionPct: 0.1,
                reason: "Moderate fatigue - slight reduction to support recovery",
                fatigueBand: fatigue.fatigueBand,
                isDeloadWeek: fatigue.deloadRecommended
            )
        case .low:
            // No adjustment needed for low fatigue
            return nil
        }
    }

    /// Create from active deload period
    static func from(deload: ActiveDeloadPeriod) -> FatigueAdjustment {
        return FatigueAdjustment(
            loadReductionPct: deload.loadReductionPct,
            volumeReductionPct: deload.volumeReductionPct,
            reason: "Deload week in progress - reduced load for recovery",
            fatigueBand: .moderate, // During deload, treat as moderate fatigue band
            isDeloadWeek: true
        )
    }

    /// Adjust an original load value by the reduction percentage
    func adjustedLoad(_ originalLoad: Double) -> Double {
        return originalLoad * (1 - loadReductionPct)
    }
}

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
    @Published var isTimerVisible: Bool = true

    // Current exercise input fields
    @Published var actualSets: Int = 0
    @Published var repsPerSet: [Int] = []
    // BUILD 312: Per-set weight input (weight varies per set like reps)
    @Published var weightPerSet: [Double] = []
    @Published var loadUnit: String = "lbs"
    @Published var rpe: Double = 5.0
    @Published var painScore: Double = 0.0
    @Published var notes: String = ""

    // Fatigue-based adjustments
    @Published var fatigueAdjustment: FatigueAdjustment?

    // BUILD 312: Computed average load for saving to database (backward compatibility)
    var actualLoad: Double? {
        guard !weightPerSet.isEmpty else { return nil }
        let nonZeroWeights = weightPerSet.filter { $0 > 0 }
        guard !nonZeroWeights.isEmpty else { return nil }
        return nonZeroWeights.reduce(0, +) / Double(nonZeroWeights.count)
    }

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
    /// BUILD 309: Added secondary sort by block name to prevent unstable category header reordering
    var exercisesByBlock: [(blockType: String, exercises: [ManualSessionExercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.blockType ?? "General" }
        // Sort by workout block order with secondary sort by name for stability
        return grouped.sorted { lhs, rhs in
            let order1 = WorkoutBlockType.sortOrder(for: lhs.key)
            let order2 = WorkoutBlockType.sortOrder(for: rhs.key)
            if order1 != order2 {
                return order1 < order2
            }
            // Secondary sort by block name for stable ordering when sort orders match
            return lhs.key < rhs.key
        }
        .map { ($0.key, $0.value.sorted { lhs, rhs in
            if lhs.sequence != rhs.sequence {
                return lhs.sequence < rhs.sequence
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }) }
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
                targetSets: exercise.sets,
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
        let sets = exercise.targetSets ?? 3
        actualSets = sets
        repsPerSet = Array(repeating: Int(exercise.targetReps ?? "10") ?? 10, count: sets)

        // BUILD 312: Initialize weight per set with target load
        // Apply fatigue adjustment if present
        var defaultWeight = exercise.targetLoad ?? 0
        if let adjustment = fatigueAdjustment, adjustment.isActive {
            // Reduce weight by the fatigue adjustment percentage
            defaultWeight *= (1.0 - adjustment.loadReductionPct)
            // Round to nearest 5 for practical gym use
            defaultWeight = (defaultWeight / 5.0).rounded() * 5.0
        }

        weightPerSet = Array(repeating: defaultWeight, count: sets)
        loadUnit = exercise.loadUnit ?? "lbs"
        rpe = 5.0
        painScore = 0.0
        notes = ""
    }

    /// Apply fatigue adjustment to an exercise
    /// - Parameters:
    ///   - adjustment: The fatigue adjustment to apply (or nil to clear)
    func applyFatigueAdjustment(_ adjustment: FatigueAdjustment?) {
        fatigueAdjustment = adjustment

        // Re-setup input fields for current exercise with the new adjustment
        if let currentExercise = currentExercise {
            setupInputFields(for: currentExercise)
        }
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
            // BUILD 312: actualLoad is now computed from weightPerSet array
            if isPrescribedSession, let originalId = prescribedExerciseIdMap[exercise.id] {
                // Log to exercise_logs with session_exercise_id
                try await service.logPrescribedExercise(
                    sessionExerciseId: originalId,
                    patientId: patientId,
                    actualSets: actualSets,
                    actualReps: Array(repsPerSet.prefix(actualSets)),
                    actualLoad: actualLoad,
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
                    actualLoad: actualLoad,
                    loadUnit: loadUnit,
                    rpe: Int(rpe),
                    painScore: Int(painScore),
                    notes: notes.isEmpty ? nil : notes
                )
            }

            completedExerciseIds.insert(exercise.id)

            // Haptic feedback for exercise completion
            HapticFeedback.success()

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

            // Haptic feedback for quick exercise completion
            HapticFeedback.success()

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
            // BUILD 309: Pass startTime for proper session summary filtering
            if isPrescribedSession, let prescribedId = prescribedSessionId {
                // Prescribed sessions are in the sessions table
                try await service.completePrescribedSession(
                    prescribedId,
                    startedAt: startTime,
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

            // Haptic feedback for workout completion
            HapticFeedback.success()

            DebugLogger.shared.success("MANUAL_WORKOUT", """
                Workout completed:
                Duration: \(durationMinutes) minutes
                Volume: \(Int(totalVolume)) lbs
                Exercises: \(completedCount)/\(totalExercises)
                """)

            // Update program enrollment progress if this workout is from a program template
            // This runs asynchronously and won't block the completion flow
            if let sourceTemplateId = session.sourceTemplateId {
                Task {
                    let programService = ProgramLibraryService()
                    try? await programService.recordWorkoutCompletion(
                        patientId: patientId.uuidString,
                        templateId: sourceTemplateId
                    )
                }
            }

            isLoading = false
            isWorkoutCompleted = true

        } catch {
            DebugLogger.shared.error("MANUAL_WORKOUT", "Failed to complete workout: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }

    // MARK: - Reps and Weight Array Management

    func updateSetsCount(_ newCount: Int) {
        let previousCount = repsPerSet.count
        if newCount > previousCount {
            // Add more sets with default reps and weights
            let defaultReps = repsPerSet.last ?? 10
            let defaultWeight = weightPerSet.last ?? 0
            repsPerSet.append(contentsOf: Array(repeating: defaultReps, count: newCount - previousCount))
            weightPerSet.append(contentsOf: Array(repeating: defaultWeight, count: newCount - previousCount))
        } else if newCount < previousCount {
            repsPerSet = Array(repsPerSet.prefix(newCount))
            weightPerSet = Array(weightPerSet.prefix(newCount))
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

// MARK: - Gesture-Based Input Components
// NOTE: TappableRepCounter, SwipeableWeightControl, GestureSetRow, GestureHintOverlay,
// and SwipeableExerciseRow have been extracted to Components/SetLoggingComponents.swift

// MARK: - Main View

/// View for executing manual workouts with exercise logging
struct ManualWorkoutExecutionView: View {
    @StateObject private var viewModel: ManualWorkoutExecutionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var supabase: PTSupabaseClient  // BUILD 261: For exercise picker sheet
    // ACP-515: Removed showEndEarlyConfirmation - using undo pattern instead
    @State private var expandedExercises: Set<UUID> = []  // BUILD 216: Track expanded exercises
    let onComplete: (() -> Void)?

    // BUILD 260: Exercise detail, AI substitution, and add exercise
    @State private var showExerciseDetail = false
    @State private var selectedExerciseForDetail: ManualSessionExercise?
    @State private var showAISubstitution = false
    @State private var selectedExerciseForSubstitution: ManualSessionExercise?
    @State private var showAddExercise = false

    // BUILD 309: Collapsible RPE/Pain section - hidden by default for simplified logging
    @State private var showAdvancedOptions = false

    // Auto-Start Rest Timer state
    @State private var showRestTimer = false
    @State private var restDuration: TimeInterval = 90  // Default 90 seconds
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var restTimer: Timer?

    // Gesture hints state
    @State private var showGestureHints = false

    // Fatigue and progression state
    @State private var fatigueAdjustment: FatigueAdjustment?
    @State private var progressionSuggestion: ProgressionSuggestion?
    @State private var showProgressionSuggestion = false
    @State private var showFatigueInfo = false
    @StateObject private var progressiveOverloadService = ProgressiveOverloadAIService()
    @StateObject private var fatigueService = FatigueTrackingService()
    @StateObject private var deloadService = DeloadRecommendationService()

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
        NavigationStack {
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
                    // ACP-515: End immediately without confirmation, provide undo
                    Button("End") {
                        if viewModel.completedCount > 0 {
                            // End workout immediately - trust the user
                            let completedCount = viewModel.completedCount
                            let totalCount = viewModel.totalExercises
                            let workoutName = viewModel.workoutName

                            // Store state snapshot for potential undo
                            let skippedSnapshot = viewModel.skippedExerciseIds
                            let completedSnapshot = viewModel.completedExerciseIds

                            Task {
                                await viewModel.completeWorkout()

                                // Register undo action
                                PTUndoManager.shared.registerEndWorkout(
                                    workoutName: workoutName,
                                    completedExercises: completedCount,
                                    totalExercises: totalCount
                                ) { [weak viewModel] in
                                    // Restore workout state
                                    viewModel?.skippedExerciseIds = skippedSnapshot
                                    viewModel?.completedExerciseIds = completedSnapshot
                                    viewModel?.isWorkoutCompleted = false
                                }
                            }
                        } else {
                            onComplete?()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("End workout")
                    .accessibilityHint(viewModel.completedCount > 0 ? "Saves your progress and ends the workout" : "Exits without saving")
                }
            }
            .task {
                DebugLogger.shared.log("ManualWorkoutExecutionView task started", level: .diagnostic)
                DebugLogger.shared.log("Session ID: \(viewModel.session.id)", level: .diagnostic)
                DebugLogger.shared.log("Initial exercise count: \(viewModel.exercises.count)", level: .diagnostic)

                // Load exercises if needed (for convenience init)
                await viewModel.loadExercisesIfNeeded()

                DebugLogger.shared.log("After load, exercise count: \(viewModel.exercises.count)", level: .diagnostic)

                // Load fatigue state for adjustments banner
                await loadFatigueState()

                // Start the timer
                viewModel.startTimer()
                DebugLogger.shared.log("Timer started", level: .success)
            }
            .onChange(of: viewModel.isWorkoutCompleted) { _, isCompleted in
                // Call onComplete when workout finishes
                if isCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete?()
                    }
                }
            }
            // ACP-515: Removed confirmation dialog - using undo pattern instead
            // Undo toasts are shown at the bottom of the screen
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
                    NavigationStack {
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
                NavigationStack {
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
                // Clean up rest timer
                restTimer?.invalidate()
                restTimer = nil
            }
            // ACP-515: Add undo toast overlay for immediate actions
            .withUndoToasts()
        }
    }

    // MARK: - Workout Execution View

    @ViewBuilder
    private var workoutExecutionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Fatigue Adjustment Banner (when active)
                if let adjustment = fatigueAdjustment, adjustment.isActive {
                    fatigueAdjustmentBanner(adjustment)
                }

                // Progress Header
                progressHeader

                // AI Progression Suggestion (after completing a set)
                if showProgressionSuggestion, let suggestion = progressionSuggestion {
                    progressionSuggestionCard(suggestion)
                }

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
        // Rest Timer Overlay - shows after completing an exercise
        .overlay {
            if showRestTimer {
                RestTimerOverlay(
                    timeRemaining: restTimeRemaining,
                    totalTime: restDuration,
                    onSkip: skipRest,
                    onAdjust: adjustRestTime,
                    exerciseCategory: viewModel.currentExercise?.blockName
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // BUILD 320: Gesture hints overlay
        .overlay {
            GestureHintOverlay(isVisible: $showGestureHints)
        }
    }

    // MARK: - Fatigue Adjustment Banner

    private func fatigueAdjustmentBanner(_ adjustment: FatigueAdjustment) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Orange recovery icon
                Image(systemName: adjustment.isDeloadWeek ? "bed.double.circle.fill" : "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Adjusted for Recovery")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text("Adjusted: \(Int(adjustment.loadReductionPct * 100))% lighter for recovery")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Show volume reduction if different from load reduction
                    if adjustment.volumeReductionPct != adjustment.loadReductionPct {
                        Text("Volume reduced by \(adjustment.volumeReductionPercent)%")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }

                Spacer()

                // Fatigue band indicator
                Text(adjustment.fatigueBand.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(adjustment.fatigueBand.color.opacity(0.2))
                    .foregroundColor(adjustment.fatigueBand.color)
                    .cornerRadius(CornerRadius.sm)

                // Info button
                Button {
                    showFatigueInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                .accessibilityLabel("Fatigue adjustment details")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .alert("Recovery Adjustment", isPresented: $showFatigueInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(adjustment.reason)
        }
    }

    // MARK: - Progression Suggestion Card (using reusable component)

    private func progressionSuggestionCard(_ suggestion: ProgressionSuggestion) -> some View {
        ProgressionSuggestionCard(
            suggestion: suggestion,
            onApply: { applyProgressionSuggestion(suggestion) },
            onDismiss: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showProgressionSuggestion = false
                }
            }
        )
    }

    private func applyProgressionSuggestion(_ suggestion: ProgressionSuggestion) {
        // Apply the suggested weight to all sets
        for i in 0..<viewModel.weightPerSet.count {
            viewModel.weightPerSet[i] = suggestion.nextLoad
        }

        // Apply suggested reps
        for i in 0..<viewModel.repsPerSet.count {
            viewModel.repsPerSet[i] = suggestion.nextReps
        }

        // Clear the suggestion after applying
        withAnimation(.easeOut(duration: 0.2)) {
            showProgressionSuggestion = false
        }

        HapticFeedback.success()
    }

    // MARK: - Load Adjustment Helper

    /// Adjust a base load value based on active deload or fatigue adjustment
    /// - Parameter baseLoad: The original prescribed load
    /// - Returns: The adjusted load accounting for any active deload/fatigue reduction
    private func adjustedLoad(baseLoad: Double) -> Double {
        if let activeDeload = deloadService.activeDeload, activeDeload.isActive {
            return baseLoad * (1 - activeDeload.loadReductionPct)
        }
        if let adjustment = fatigueAdjustment, adjustment.isActive {
            return adjustment.adjustedLoad(baseLoad)
        }
        return baseLoad
    }

    // MARK: - Progress Header
    // NOTE: Progress header view extracted to Components/WorkoutProgressHeader.swift

    @ViewBuilder
    private var progressHeader: some View {
        WorkoutProgressHeader(
            elapsedTimeDisplay: viewModel.elapsedTimeDisplay,
            progressText: viewModel.progressText,
            completedCount: viewModel.completedCount,
            totalExercises: viewModel.totalExercises,
            progressPercentage: viewModel.progressPercentage,
            isTimerVisible: $viewModel.isTimerVisible
        )
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
                            .id(exercise.id)
                    }
                }
                .id(block.blockType)
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
        .padding(Spacing.sm)
        .background(isCurrent ? Color.modusCyan.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(blockTypeEnum?.displayName ?? blockType) block, \(exercises.filter { viewModel.completedExerciseIds.contains($0.id) }.count) of \(exercises.count) completed")
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
    }

    // BUILD 216: Expandable exercise row with inline completion
    // BUILD 320: Added swipe gestures for quick complete/skip
    private func exerciseRow(_ exercise: ManualSessionExercise) -> some View {
        let isCompleted = viewModel.completedExerciseIds.contains(exercise.id)
        let isSkipped = viewModel.skippedExerciseIds.contains(exercise.id)
        let isCurrent = viewModel.currentExercise?.id == exercise.id
        let isExpanded = expandedExercises.contains(exercise.id)

        return SwipeableExerciseRow(
            exercise: exercise,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            onComplete: {
                Task {
                    await viewModel.quickCompleteExercise(exercise)
                    if hasMoreExercises {
                        startRestTimer()
                    }
                }
            },
            onSkip: {
                // ACP-515: Skip immediately with undo support
                viewModel.skipExercise(exercise)

                // Register undo action
                PTUndoManager.shared.registerSkipExercise(
                    exerciseId: exercise.id,
                    exerciseName: exercise.exerciseName
                ) { [weak viewModel] in
                    viewModel?.skippedExerciseIds.remove(exercise.id)
                }
            }
        ) {
            VStack(spacing: 0) {
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
                            .accessibilityHidden(true)
                    } else if isSkipped {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                    } else if isCurrent {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(.modusCyan)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .accessibilityHidden(true)
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
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 10)
                .background(isCurrent ? Color.modusCyan.opacity(0.08) : Color(.systemBackground))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(exerciseAccessibilityLabel(exercise: exercise, isCompleted: isCompleted, isSkipped: isSkipped, isCurrent: isCurrent))
            .accessibilityHint(isCompleted || isSkipped ? "" : (isExpanded ? "Double tap to collapse" : "Double tap to expand options"))

            // Expanded content
            if isExpanded && !isCompleted && !isSkipped {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, Spacing.sm)

                    // Quick complete button
                    Button {
                        Task {
                            await viewModel.quickCompleteExercise(exercise)
                            _ = withAnimation {
                                expandedExercises.remove(exercise.id)
                            }
                            // Auto-start rest timer if there are more exercises
                            if hasMoreExercises {
                                startRestTimer()
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
                        .cornerRadius(CornerRadius.sm)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .accessibilityLabel("Complete as prescribed")
                    .accessibilityHint("Logs this exercise with the prescribed sets and reps")

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
                        .background(Color.modusCyan.opacity(0.1))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .accessibilityLabel("Log with custom values")
                    .accessibilityHint("Opens detailed logging to enter actual sets, reps, and weight")

                    // Skip button - ACP-515: Immediate action with undo
                    Button {
                        viewModel.skipExercise(exercise)
                        _ = withAnimation {
                            expandedExercises.remove(exercise.id)
                        }

                        // Register undo action
                        PTUndoManager.shared.registerSkipExercise(
                            exerciseId: exercise.id,
                            exerciseName: exercise.exerciseName
                        ) { [weak viewModel] in
                            viewModel?.skippedExerciseIds.remove(exercise.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Exercise")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    .padding(.bottom, Spacing.xs)
                    .accessibilityLabel("Skip exercise")
                    .accessibilityHint("Skips this exercise and marks it as not completed")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            }
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.modusCyan.opacity(0.3) : Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
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
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Exercise details")
                    .accessibilityHint("Shows video demonstration and technique cues")

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
                    .accessibilityHint("Opens AI-powered exercise substitution finder")

                    // Add exercise button
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .accessibilityLabel("Add exercise")
                    .accessibilityHint("Adds a new exercise to this workout")
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

            // BUILD 317: Combined Reps & Weight Per Set Input with gesture controls
            // BUILD 320: Added gesture-based input for faster logging
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Sets")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        // Gesture hint button
                        Button {
                            withAnimation(.easeIn(duration: 0.2)) {
                                showGestureHints = true
                            }
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.subheadline)
                                .foregroundColor(.modusCyan)
                        }
                        .accessibilityLabel("Show gesture hints")
                    }

                    Spacer()

                    Picker("Unit", selection: $viewModel.loadUnit) {
                        Text("lbs").tag("lbs")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                // Gesture hint text
                Text("Tap reps: +1 | Long press: -1 | Swipe weight: +/-5")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, Spacing.xxs)

                // Gesture-enabled set rows
                ForEach(0..<viewModel.actualSets, id: \.self) { index in
                    let prescribedReps = Int(viewModel.currentExercise?.targetReps ?? "10") ?? 10
                    let prescribedWeight = viewModel.currentExercise?.targetLoad ?? 0

                    GestureSetRow(
                        setNumber: index + 1,
                        reps: Binding(
                            get: { viewModel.repsPerSet[safe: index] ?? prescribedReps },
                            set: { newValue in
                                if index < viewModel.repsPerSet.count {
                                    viewModel.repsPerSet[index] = newValue
                                }
                            }
                        ),
                        weight: Binding(
                            get: { viewModel.weightPerSet[safe: index] ?? prescribedWeight },
                            set: { newValue in
                                if index < viewModel.weightPerSet.count {
                                    viewModel.weightPerSet[index] = newValue
                                }
                            }
                        ),
                        prescribedReps: prescribedReps,
                        prescribedWeight: prescribedWeight,
                        loadUnit: viewModel.loadUnit
                    )
                    .id("\(viewModel.currentExercise?.id.uuidString ?? "set")-\(index)")
                }
            }

            // BUILD 309: Collapsible RPE/Pain section - hidden by default for simplified logging
            DisclosureGroup(
                isExpanded: $showAdvancedOptions,
                content: {
                    VStack(spacing: 16) {
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
                                .tint(rpeColor(Int(viewModel.rpe)))
                                .accessibilityLabel("Rate of perceived exertion")
                                .accessibilityValue("\(Int(viewModel.rpe)) out of 10")

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
                                .tint(painColor(Int(viewModel.painScore)))
                                .accessibilityLabel("Pain score")
                                .accessibilityValue("\(Int(viewModel.painScore)) out of 10")

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
                    }
                    .padding(.top, Spacing.xs)
                },
                label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.secondary)
                        Text("Exertion & Pain")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if !showAdvancedOptions {
                            Text("RPE: \(Int(viewModel.rpe)) | Pain: \(Int(viewModel.painScore))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            )
            .tint(.secondary)

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
                    .accessibilityLabel("Exercise notes")
                    .accessibilityHint("Optional notes about how this exercise felt")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Complete Exercise Button
            Button {
                Task {
                    await viewModel.completeCurrentExercise()
                    // Request AI progression suggestion for next exercise
                    onSetCompleted()
                    // Auto-start rest timer if there are more exercises
                    if hasMoreExercises {
                        startRestTimer()
                    }
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
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.currentExercise == nil)
            .accessibilityLabel("Complete exercise")
            .accessibilityHint("Logs your sets and reps for this exercise")

            // Skip Exercise Button - ACP-515: Immediate action with undo
            Button {
                if let exercise = viewModel.currentExercise {
                    viewModel.skipCurrentExercise()

                    // Register undo action
                    PTUndoManager.shared.registerSkipExercise(
                        exerciseId: exercise.id,
                        exerciseName: exercise.exerciseName
                    ) { [weak viewModel] in
                        viewModel?.skippedExerciseIds.remove(exercise.id)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip Exercise")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.currentExercise == nil)
            .accessibilityLabel("Skip exercise")
            .accessibilityHint("Skips this exercise and moves to the next one")

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
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Complete workout")
                .accessibilityHint("Finishes the workout and shows your summary")
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
            .padding(Spacing.xl)
            .background(Color(.systemGray3).opacity(0.9))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Workout Completed View
    // NOTE: Workout completion view extracted to Components/WorkoutCompletionView.swift

    private var workoutCompletedView: some View {
        WorkoutCompletionView(
            workoutName: viewModel.workoutName,
            elapsedTimeDisplay: viewModel.elapsedTimeDisplay,
            completedCount: viewModel.completedCount,
            totalExercises: viewModel.totalExercises,
            volumeDisplay: viewModel.volumeDisplay,
            averageRPE: viewModel.averageRPE,
            averagePain: viewModel.averagePain,
            onDismiss: { dismiss() }
        )
    }

    // MARK: - Fatigue & Progression Helpers

    /// Load fatigue state for the patient
    /// Checks for active deload period first, then falls back to fatigue accumulation
    private func loadFatigueState() async {
        // First check if patient is in an active deload period
        do {
            if let activeDeload = try await deloadService.checkActiveDeload(), activeDeload.isActive {
                // Use deload settings for adjustment
                let adjustment = FatigueAdjustment.from(deload: activeDeload)
                fatigueAdjustment = adjustment
                viewModel.applyFatigueAdjustment(adjustment)
                DebugLogger.shared.info("FATIGUE", "Active deload period found - load: -\(Int(activeDeload.loadReductionPct * 100))%, volume: -\(Int(activeDeload.volumeReductionPct * 100))%")
                return
            }
        } catch {
            DebugLogger.shared.warning("FATIGUE", "Failed to check active deload: \(error.localizedDescription)")
        }

        // If no active deload, check fatigue accumulation
        do {
            try await fatigueService.fetchCurrentFatigue(patientId: viewModel.patientId)
            if let fatigue = fatigueService.currentFatigue {
                let adjustment = FatigueAdjustment.from(fatigue: fatigue)
                fatigueAdjustment = adjustment
                // Apply to viewModel so it adjusts weights automatically
                viewModel.applyFatigueAdjustment(adjustment)

                if let adj = adjustment {
                    DebugLogger.shared.info("FATIGUE", "Fatigue adjustment applied - band: \(fatigue.fatigueBand.displayName), load: -\(adj.loadReductionPercent)%")
                }
            }
        } catch {
            DebugLogger.shared.error("FATIGUE", "Failed to load fatigue state: \(error.localizedDescription)")
        }
    }

    /// Request AI progression suggestion after completing a set
    private func onSetCompleted() {
        guard let exercise = viewModel.currentExercise,
              let templateId = exercise.exerciseTemplateId else {
            return
        }

        // Get current weight and reps from what was just logged
        let currentLoad = viewModel.actualLoad ?? exercise.targetLoad ?? 0
        let currentReps = viewModel.repsPerSet.first ?? Int(exercise.targetReps ?? "10") ?? 10

        Task {
            do {
                let suggestion = try await progressiveOverloadService.getSuggestion(
                    patientId: viewModel.patientId,
                    exerciseTemplateId: templateId,
                    currentLoad: currentLoad,
                    currentReps: currentReps,
                    recentRPE: viewModel.rpe
                )

                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.3)) {
                        progressionSuggestion = suggestion
                        showProgressionSuggestion = true
                    }
                }
            } catch {
                DebugLogger.shared.error("PROGRESSION", "Failed to get suggestion: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Rest Timer Methods

    /// Start the rest timer after exercise completion
    private func startRestTimer() {
        // Get rest duration from current exercise, default to 90 seconds
        restDuration = TimeInterval(viewModel.currentExercise?.restPeriodSeconds ?? 90)
        restTimeRemaining = restDuration
        showRestTimer = true

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                endRestTimer()
            }
        }
    }

    /// End rest timer and advance to next exercise
    private func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false

        // Haptic feedback when rest ends
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto-advance to next exercise (already handled by completeCurrentExercise -> moveToNextExercise)
    }

    /// Skip rest and advance immediately
    private func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false
    }

    /// Adjust rest time on-the-fly
    private func adjustRestTime(_ adjustment: TimeInterval) {
        restTimeRemaining = max(0, restTimeRemaining + adjustment)
        restDuration = max(restDuration, restTimeRemaining) // Ensure totalTime reflects adjustment
    }

    /// Check if there are more exercises to complete
    private var hasMoreExercises: Bool {
        viewModel.completedCount < viewModel.totalExercises
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

    // MARK: - Accessibility Helpers

    private func exerciseAccessibilityLabel(exercise: ManualSessionExercise, isCompleted: Bool, isSkipped: Bool, isCurrent: Bool) -> String {
        let displayName = exercise.exerciseName.count <= 2 && Int(exercise.exerciseName) != nil
            ? (exercise.notes ?? exercise.exerciseName)
            : exercise.exerciseName

        var statusText = ""
        if isCompleted {
            statusText = ", completed"
        } else if isSkipped {
            statusText = ", skipped"
        } else if isCurrent {
            statusText = ", current exercise"
        }

        let prescription = "\(exercise.targetSets ?? 3) sets, \(exercise.targetReps ?? "10") reps"
        let loadText = exercise.targetLoad.map { ", \(Int($0)) \(exercise.loadUnit ?? "lbs")" } ?? ""

        return "\(displayName)\(statusText), \(prescription)\(loadText)"
    }
}

// MARK: - Rest Timer Overlay
// NOTE: RestTimerOverlay extracted to Components/RestTimerOverlay.swift

// MARK: - BUILD 285: Exercise Info Sheet (with video, technique cues, safety notes)

/// Full exercise detail view that fetches template data for video + technique tips
struct ExerciseInfoSheet: View {
    let exercise: ManualSessionExercise
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabase: PTSupabaseClient

    @State private var template: Exercise.ExerciseTemplate?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
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
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.modusCyan.opacity(0.1))
                                    .foregroundColor(.modusCyan)
                                    .cornerRadius(CornerRadius.sm)
                            }
                            if let category = template?.category {
                                Label(category.capitalized, systemImage: "tag")
                                    .font(.caption)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(CornerRadius.sm)
                            }
                            if let bodyRegion = template?.body_region {
                                Label(bodyRegion.capitalized, systemImage: "figure.arms.open")
                                    .font(.caption)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(CornerRadius.sm)
                            }
                        }
                    }

                    // Video Player
                    if let videoUrl = template?.videoUrl, !videoUrl.isEmpty {
                        VideoPlayerView(videoUrl: videoUrl)
                            .frame(height: 220)
                            .cornerRadius(CornerRadius.md)
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)

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
                                            .foregroundColor(.modusCyan)
                                            .frame(width: 24)

                                        Text(cue.cue)
                                            .font(.subheadline)

                                        Spacer()

                                        if let time = cue.displayTime {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, Spacing.xs)
                                                .padding(.vertical, 2)
                                                .background(Color(.tertiarySystemGroupedBackground))
                                                .cornerRadius(CornerRadius.xs)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.md)
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
                        .cornerRadius(CornerRadius.md)
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
                        .cornerRadius(CornerRadius.md)
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
        do {
            // BUILD 354: Try by ID first, fallback to name-based lookup
            let selectFields = "id, name, category, body_region, video_url, video_thumbnail_url, video_duration, form_cues, technique_cues, common_mistakes, safety_notes"

            if let templateId = exercise.exerciseTemplateId {
                // Lookup by ID
                let response = try await supabase.client
                    .from("exercise_templates")
                    .select(selectFields)
                    .eq("id", value: templateId.uuidString)
                    .limit(1)
                    .execute()

                let templates = try JSONDecoder().decode([Exercise.ExerciseTemplate].self, from: response.data)
                template = templates.first
            } else {
                // Fallback: fuzzy match by exercise name (for workout templates without FK)
                let response = try await supabase.client
                    .from("exercise_templates")
                    .select(selectFields)
                    .ilike("name", pattern: "%\(exercise.exerciseName)%")
                    .limit(1)
                    .execute()

                let templates = try JSONDecoder().decode([Exercise.ExerciseTemplate].self, from: response.data)
                template = templates.first
            }
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
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(CornerRadius.sm)
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
                                                        .foregroundColor(.modusCyan)
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
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(CornerRadius.sm)
                                }
                                .id(alt.id)
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
                        .padding(.top, Spacing.xs)
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
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
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
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(
                                    (selectedCategory == nil && category == "All") || selectedCategory == category
                                    ? Color.modusCyan
                                    : Color(.tertiarySystemGroupedBackground)
                                )
                                .foregroundColor(
                                    (selectedCategory == nil && category == "All") || selectedCategory == category
                                    ? .white
                                    : .primary
                                )
                                .cornerRadius(CornerRadius.lg)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)
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
                                                .background(Color.modusCyan.opacity(0.7))
                                                .cornerRadius(CornerRadius.xs)
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
                            .padding(.vertical, Spacing.xxs)
                        }
                        .id(template.id)
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

// MARK: - Progression Suggestion Card Component

/// Reusable component for displaying AI-powered progressive overload suggestions
/// Shows the recommended load/rep progression with confidence indicator and reasoning
struct ProgressionSuggestionCard: View {
    let suggestion: ProgressionSuggestion
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: suggestion.progressionType.icon)
                    .font(.title2)
                    .foregroundColor(suggestion.progressionType.color)

                Text("AI Suggestion")
                    .font(.headline)

                Spacer()

                // Confidence indicator
                Text("\(Int(suggestion.confidence))% confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            // Next set recommendation
            HStack(spacing: 16) {
                Text("Next set: \(Int(suggestion.nextLoad)) x \(suggestion.nextReps)")
                    .font(.headline)

                Spacer()

                // Progression type badge
                Text(suggestion.progressionType.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(suggestion.progressionType.color.opacity(0.2))
                    .foregroundColor(suggestion.progressionType.color)
                    .cornerRadius(CornerRadius.sm)
            }

            // Reasoning text
            Text(suggestion.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // Use This Weight button
            Button(action: onApply) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Use This Weight")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .shadow(radius: 2)
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
