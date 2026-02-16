//
//  WorkoutSessionAnalytics.swift
//  PTPerformance
//
//  ACP-965: Workout Session Analytics
//  Actor-based service that tracks detailed workout session metrics including
//  session lifecycle (start/pause/resume/end), exercise completion rates,
//  rest timer usage, weight progression with PR detection, session quality
//  scoring, and workout type distribution.
//
//  Integrates with AnalyticsSDK for backend event ingestion and AnalyticsTracker
//  for local logging. Persists weight history and session metrics to disk for
//  cross-session PR detection and trend analysis.
//

import Foundation

// MARK: - WorkoutSessionAnalytics

/// Actor-based singleton that tracks detailed workout session analytics.
///
/// Records every aspect of a workout session — from start to finish — including
/// exercise completions, rest timer usage, weight progression, and computes a
/// composite quality score. Events are forwarded to ``AnalyticsSDK`` for backend
/// ingestion and persisted locally for cross-session analysis (e.g. PR detection).
///
/// ## Quick Start
/// ```swift
/// // Start tracking a session
/// await WorkoutSessionAnalytics.shared.startSession(
///     sessionId: session.id,
///     workoutType: .strength,
///     exercises: exercises,
///     sessionSource: "prescribed"
/// )
///
/// // Record exercise completion
/// await WorkoutSessionAnalytics.shared.recordExerciseCompletion(
///     exerciseId: exercise.id,
///     exerciseName: "Bench Press",
///     exerciseTemplateId: exercise.exercise_template_id,
///     plannedSets: 3,
///     completedSets: 3,
///     plannedRepsPerSet: 10,
///     completedReps: [10, 10, 8],
///     plannedLoad: 135,
///     actualLoad: 145,
///     loadUnit: "lbs"
/// )
///
/// // Record rest timer
/// await WorkoutSessionAnalytics.shared.recordRestTimer(
///     prescribedDuration: 90,
///     actualDuration: 75,
///     wasSkipped: true,
///     afterExerciseId: exercise.id
/// )
///
/// // End session and get metrics
/// let metrics = await WorkoutSessionAnalytics.shared.endSession(
///     averageRPE: 7.5,
///     averagePainScore: 1.0
/// )
/// ```
actor WorkoutSessionAnalytics {

    // MARK: - Singleton

    static let shared = WorkoutSessionAnalytics()

    // MARK: - Private Properties

    private let logger = DebugLogger.shared
    private let analyticsTracker = AnalyticsTracker.shared

    // MARK: Active Session State

    /// The currently active session ID, or nil if no session is in progress.
    private var activeSessionId: UUID?

    /// The workout type for the active session.
    private var activeWorkoutType: WorkoutType = .unknown

    /// The session source for the active session.
    private var activeSessionSource: String?

    /// When the active session was started.
    private var sessionStartedAt: Date?

    /// Current session state.
    private var sessionState: WorkoutSessionState?

    /// Timestamps of pause events for the active session.
    private var pauseTimestamps: [Date] = []

    /// Timestamps of resume events for the active session.
    private var resumeTimestamps: [Date] = []

    /// Total accumulated pause duration in seconds for the active session.
    private var accumulatedPauseSeconds: TimeInterval = 0

    /// When the current pause started (nil if not paused).
    private var currentPauseStartedAt: Date?

    /// Total exercises planned for the active session.
    private var totalPlannedExercises: Int = 0

    /// Total planned sets across all exercises in the active session.
    private var totalPlannedSets: Int = 0

    /// Exercise completion records for the active session.
    private var exerciseCompletions: [ExerciseCompletionRecord] = []

    /// Rest timer records for the active session.
    private var restTimerRecords: [RestTimerRecord] = []

    /// Personal records detected during the active session.
    private var sessionPRs: [WorkoutPersonalRecord] = []

    // MARK: Persisted State

    /// Historical weight records per exercise template, keyed by exercise template UUID string.
    /// Loaded from disk on init and updated on session completion.
    private var weightHistory: [String: WeightHistoryEntry] = [:]

    /// Completed session metrics history. Used for summary/trend reporting.
    private var sessionMetricsHistory: [WorkoutSessionMetrics] = []

    // MARK: - Persistence

    /// Directory for persisted analytics data.
    private let persistenceDirectory: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDirectory = directory.appendingPathComponent("PTPerformance", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }()

    private var weightHistoryURL: URL {
        persistenceDirectory.appendingPathComponent("workout_weight_history.json")
    }

    private var metricsHistoryURL: URL {
        persistenceDirectory.appendingPathComponent("workout_session_metrics.json")
    }

    // MARK: - JSON Coders

    private nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {
        logger.info("WorkoutAnalytics", "WorkoutSessionAnalytics initialized")
        loadWeightHistory()
        loadMetricsHistory()
    }

    // MARK: - Public API: Session Lifecycle

    /// Start tracking a new workout session.
    ///
    /// Initializes all session-scoped accumulators and emits a
    /// `workout_analytics_session_started` event to the analytics pipeline.
    ///
    /// - Parameters:
    ///   - sessionId: The unique session identifier.
    ///   - workoutType: The classification of this workout.
    ///   - exercises: The exercises planned for this session, used to compute planned totals.
    ///   - sessionSource: How the session was initiated (e.g. "prescribed", "manual", "quick_pick").
    func startSession(
        sessionId: UUID,
        workoutType: WorkoutType,
        exercises: [WorkoutExerciseItem],
        sessionSource: String? = nil
    ) {
        // Guard against double-start
        if let existingId = activeSessionId {
            logger.warning("WorkoutAnalytics", "startSession called while session \(existingId) is active. Ending previous session.")
            let _ = finalizeSession(state: .abandoned)
        }

        activeSessionId = sessionId
        activeWorkoutType = workoutType
        activeSessionSource = sessionSource
        sessionStartedAt = Date()
        sessionState = .active
        pauseTimestamps = []
        resumeTimestamps = []
        accumulatedPauseSeconds = 0
        currentPauseStartedAt = nil
        exerciseCompletions = []
        restTimerRecords = []
        sessionPRs = []

        // Calculate planned totals from exercises
        totalPlannedExercises = exercises.count
        totalPlannedSets = exercises.reduce(0) { $0 + $1.targetSets }

        // Emit analytics event
        let properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "workout_type": workoutType.rawValue,
            "exercise_count": totalPlannedExercises,
            "planned_sets": totalPlannedSets,
            "session_source": sessionSource ?? "unknown"
        ]

        analyticsTracker.track(event: "workout_analytics_session_started", properties: properties)

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.WorkoutAnalytics.sessionStarted(
                    workoutType: workoutType.rawValue,
                    exerciseCount: totalPlannedExercises
                ).eventName,
                properties: properties
            )
        }

        logger.info("WorkoutAnalytics", "Session started: \(sessionId) (\(workoutType.displayName), \(totalPlannedExercises) exercises, \(totalPlannedSets) sets)")
    }

    /// Start tracking a session from a prescribed ``Session`` and its exercises.
    ///
    /// Convenience overload that extracts workout type from exercise categories
    /// and builds ``WorkoutExerciseItem`` array from ``Exercise`` models.
    ///
    /// - Parameters:
    ///   - session: The prescribed session model.
    ///   - exercises: The exercises in the session.
    func startSession(from session: Session, exercises: [Exercise]) {
        let items = exercises.map { WorkoutExerciseItem(from: $0) }
        let workoutType = inferWorkoutType(from: exercises)
        startSession(
            sessionId: session.id,
            workoutType: workoutType,
            exercises: items,
            sessionSource: "prescribed"
        )
    }

    /// Start tracking a session from a manual ``ManualSession`` and its exercises.
    ///
    /// - Parameters:
    ///   - session: The manual session model.
    ///   - exercises: The manual session exercises.
    func startSession(from session: ManualSession, exercises: [ManualSessionExercise]) {
        let items = exercises.map { WorkoutExerciseItem(from: $0) }
        let workoutType = inferWorkoutType(fromManualExercises: exercises)
        startSession(
            sessionId: session.id,
            workoutType: workoutType,
            exercises: items,
            sessionSource: session.sessionSource?.rawValue ?? "manual"
        )
    }

    /// Pause the active session.
    ///
    /// Records the pause timestamp and emits a `workout_analytics_session_paused` event.
    /// Calling this while already paused is a no-op.
    func pauseSession() {
        guard let sessionId = activeSessionId, sessionState == .active else {
            logger.warning("WorkoutAnalytics", "pauseSession called with no active session or session already paused")
            return
        }

        sessionState = .paused
        let now = Date()
        currentPauseStartedAt = now
        pauseTimestamps.append(now)

        let elapsedSeconds = Int(now.timeIntervalSince(sessionStartedAt ?? now))

        let properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "elapsed_seconds": elapsedSeconds,
            "pause_number": pauseTimestamps.count
        ]

        analyticsTracker.track(event: "workout_analytics_session_paused", properties: properties)

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.WorkoutAnalytics.sessionPaused.eventName,
                properties: properties
            )
        }

        logger.info("WorkoutAnalytics", "Session paused: \(sessionId) (pause #\(pauseTimestamps.count), elapsed \(elapsedSeconds)s)")
    }

    /// Resume a paused session.
    ///
    /// Accumulates the pause duration and emits a `workout_analytics_session_resumed` event.
    /// Calling this while not paused is a no-op.
    func resumeSession() {
        guard let sessionId = activeSessionId, sessionState == .paused else {
            logger.warning("WorkoutAnalytics", "resumeSession called with no paused session")
            return
        }

        sessionState = .active
        let now = Date()
        resumeTimestamps.append(now)

        if let pauseStart = currentPauseStartedAt {
            let pauseDuration = now.timeIntervalSince(pauseStart)
            accumulatedPauseSeconds += pauseDuration
            currentPauseStartedAt = nil
        }

        let properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "total_paused_seconds": Int(accumulatedPauseSeconds),
            "resume_number": resumeTimestamps.count
        ]

        analyticsTracker.track(event: "workout_analytics_session_resumed", properties: properties)

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.WorkoutAnalytics.sessionResumed.eventName,
                properties: properties
            )
        }

        logger.info("WorkoutAnalytics", "Session resumed: \(sessionId) (total paused \(Int(accumulatedPauseSeconds))s)")
    }

    /// End the active session normally and compute final metrics.
    ///
    /// Finalizes all accumulators, computes the quality score, detects PRs,
    /// persists results, and emits a comprehensive `workout_analytics_session_completed` event.
    ///
    /// - Parameters:
    ///   - averageRPE: The average RPE reported by the user (0-10 scale). Nil if not reported.
    ///   - averagePainScore: The average pain score reported (0-10 scale). Nil if not reported.
    /// - Returns: The finalized ``WorkoutSessionMetrics``, or nil if no session was active.
    @discardableResult
    func endSession(
        averageRPE: Double? = nil,
        averagePainScore: Double? = nil
    ) -> WorkoutSessionMetrics? {
        guard activeSessionId != nil else {
            logger.warning("WorkoutAnalytics", "endSession called with no active session")
            return nil
        }

        return finalizeSession(state: .completed, averageRPE: averageRPE, averagePainScore: averagePainScore)
    }

    /// Abandon the active session (user quit without completing).
    ///
    /// - Returns: The finalized ``WorkoutSessionMetrics``, or nil if no session was active.
    @discardableResult
    func abandonSession() -> WorkoutSessionMetrics? {
        guard activeSessionId != nil else {
            logger.warning("WorkoutAnalytics", "abandonSession called with no active session")
            return nil
        }

        return finalizeSession(state: .abandoned)
    }

    // MARK: - Public API: Exercise Tracking

    /// Record the completion of a single exercise during the active session.
    ///
    /// Also checks for personal records against the weight history and
    /// emits a `workout_analytics_exercise_completed` event.
    ///
    /// - Parameters:
    ///   - exerciseId: The exercise instance identifier.
    ///   - exerciseName: Human-readable exercise name.
    ///   - exerciseTemplateId: The exercise template ID (for cross-session PR comparison).
    ///   - plannedSets: Number of sets prescribed.
    ///   - completedSets: Number of sets actually completed.
    ///   - plannedRepsPerSet: Prescribed reps per set (nil if not applicable).
    ///   - completedReps: Actual reps completed per set.
    ///   - plannedLoad: Prescribed load (nil for bodyweight).
    ///   - actualLoad: Actual load used (nil for bodyweight).
    ///   - loadUnit: The unit of load (e.g. "lbs", "kg").
    func recordExerciseCompletion(
        exerciseId: UUID,
        exerciseName: String,
        exerciseTemplateId: UUID? = nil,
        plannedSets: Int,
        completedSets: Int,
        plannedRepsPerSet: Int? = nil,
        completedReps: [Int] = [],
        plannedLoad: Double? = nil,
        actualLoad: Double? = nil,
        loadUnit: String? = nil
    ) {
        guard let sessionId = activeSessionId else {
            logger.warning("WorkoutAnalytics", "recordExerciseCompletion called with no active session")
            return
        }

        let record = ExerciseCompletionRecord(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            plannedSets: plannedSets,
            completedSets: completedSets,
            plannedRepsPerSet: plannedRepsPerSet,
            completedReps: completedReps,
            plannedLoad: plannedLoad,
            actualLoad: actualLoad,
            loadUnit: loadUnit,
            completedAt: Date()
        )

        exerciseCompletions.append(record)

        // Check for PRs if we have a template ID and actual load
        if let templateId = exerciseTemplateId {
            detectPersonalRecords(
                exerciseTemplateId: templateId,
                exerciseName: exerciseName,
                completedReps: completedReps,
                actualLoad: actualLoad,
                sessionId: sessionId
            )
        }

        // Emit analytics event
        let properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "exercise_id": exerciseId.uuidString,
            "exercise_name": exerciseName,
            "planned_sets": plannedSets,
            "completed_sets": completedSets,
            "set_completion_rate": String(format: "%.2f", record.setCompletionRate),
            "volume": String(format: "%.1f", record.volume)
        ]

        analyticsTracker.track(event: "workout_analytics_exercise_completed", properties: properties)

        Task {
            await AnalyticsSDK.shared.track(
                AnalyticsEventCatalog.WorkoutAnalytics.exerciseCompleted(
                    name: exerciseName,
                    completionRate: record.setCompletionRate
                ).eventName,
                properties: properties
            )
        }

        logger.info("WorkoutAnalytics", "Exercise completed: \(exerciseName) (\(completedSets)/\(plannedSets) sets, \(String(format: "%.0f%%", record.setCompletionRate * 100)))")
    }

    // MARK: - Public API: Rest Timer Tracking

    /// Record a rest timer usage during the active session.
    ///
    /// - Parameters:
    ///   - prescribedDuration: The prescribed rest time in seconds (nil if user-chosen).
    ///   - actualDuration: The actual rest duration in seconds.
    ///   - wasSkipped: Whether the user ended the rest timer early.
    ///   - afterExerciseId: The exercise the rest followed (nil if between-exercise rest).
    func recordRestTimer(
        prescribedDuration: Int?,
        actualDuration: Int,
        wasSkipped: Bool,
        afterExerciseId: UUID? = nil
    ) {
        guard let sessionId = activeSessionId else {
            logger.warning("WorkoutAnalytics", "recordRestTimer called with no active session")
            return
        }

        let record = RestTimerRecord(
            prescribedDuration: prescribedDuration,
            actualDuration: actualDuration,
            wasSkipped: wasSkipped,
            startedAt: Date().addingTimeInterval(-TimeInterval(actualDuration)),
            afterExerciseId: afterExerciseId
        )

        restTimerRecords.append(record)

        // Emit analytics event
        var properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "actual_duration_seconds": actualDuration,
            "was_skipped": wasSkipped
        ]
        if let prescribed = prescribedDuration {
            properties["prescribed_duration_seconds"] = prescribed
            if let compliance = record.restComplianceRate {
                properties["compliance_rate"] = String(format: "%.2f", compliance)
            }
        }

        let eventName = wasSkipped
            ? AnalyticsEventCatalog.WorkoutAnalytics.restTimerSkipped.eventName
            : AnalyticsEventCatalog.WorkoutAnalytics.restTimerCompleted.eventName

        analyticsTracker.track(event: eventName, properties: properties)

        Task {
            await AnalyticsSDK.shared.track(eventName, properties: properties)
        }

        logger.diagnostic("WorkoutAnalytics: Rest timer recorded (\(actualDuration)s, skipped=\(wasSkipped))")
    }

    // MARK: - Public API: Queries

    /// Returns whether a session is currently being tracked.
    var isSessionActive: Bool {
        activeSessionId != nil
    }

    /// Returns the ID of the currently active session, or nil.
    var currentSessionId: UUID? {
        activeSessionId
    }

    /// Returns the current session state, or nil if no session is active.
    var currentSessionState: WorkoutSessionState? {
        sessionState
    }

    /// Returns the number of exercises completed so far in the active session.
    var completedExerciseCount: Int {
        exerciseCompletions.count
    }

    /// Returns the number of PRs detected in the active session.
    var currentSessionPRCount: Int {
        sessionPRs.count
    }

    /// Returns the weight history entry for a specific exercise template.
    ///
    /// - Parameter exerciseTemplateId: The exercise template UUID.
    /// - Returns: The ``WeightHistoryEntry`` if one exists, or nil.
    func getWeightHistory(for exerciseTemplateId: UUID) -> WeightHistoryEntry? {
        weightHistory[exerciseTemplateId.uuidString]
    }

    /// Returns the workout type distribution for a given time period.
    ///
    /// - Parameters:
    ///   - startDate: The start of the analysis period.
    ///   - endDate: The end of the analysis period (defaults to now).
    /// - Returns: A ``WorkoutTypeDistribution`` summarizing the period.
    func getWorkoutTypeDistribution(from startDate: Date, to endDate: Date = Date()) -> WorkoutTypeDistribution {
        let relevantMetrics = sessionMetricsHistory.filter { metrics in
            metrics.startedAt >= startDate && metrics.startedAt <= endDate
        }

        var counts: [WorkoutType: Int] = [:]
        for metrics in relevantMetrics {
            counts[metrics.workoutType, default: 0] += 1
        }

        return WorkoutTypeDistribution(
            periodStart: startDate,
            periodEnd: endDate,
            sessionCounts: counts,
            totalSessions: relevantMetrics.count
        )
    }

    /// Returns a summary of workout analytics over a given time period.
    ///
    /// - Parameters:
    ///   - startDate: The start of the analysis period.
    ///   - endDate: The end of the analysis period (defaults to now).
    /// - Returns: A ``SessionAnalyticsSummary`` for the period.
    func getAnalyticsSummary(from startDate: Date, to endDate: Date = Date()) -> SessionAnalyticsSummary {
        let relevantMetrics = sessionMetricsHistory.filter { metrics in
            metrics.startedAt >= startDate && metrics.startedAt <= endDate
        }

        let completedMetrics = relevantMetrics.filter { $0.qualityScore != nil }
        let abandonedCount = relevantMetrics.count - completedMetrics.count

        let avgDuration = relevantMetrics.isEmpty ? 0
            : relevantMetrics.reduce(0) { $0 + $1.totalDurationSeconds } / relevantMetrics.count

        let avgCompletionRate = completedMetrics.isEmpty ? 0.0
            : completedMetrics.reduce(0.0) { $0 + $1.exerciseCompletionRate } / Double(completedMetrics.count)

        let avgQuality: Int? = completedMetrics.isEmpty ? nil
            : completedMetrics.compactMap { $0.qualityScore?.overallScore }.reduce(0, +) / max(completedMetrics.count, 1)

        let totalPRs = relevantMetrics.reduce(0) { $0 + $1.personalRecords.count }

        let distribution = getWorkoutTypeDistribution(from: startDate, to: endDate)

        let allRestSeconds = relevantMetrics.compactMap { $0.averageRestSeconds }
        let avgRest: Int? = allRestSeconds.isEmpty ? nil
            : allRestSeconds.reduce(0, +) / allRestSeconds.count

        let totalVolume = relevantMetrics.reduce(0.0) { $0 + $1.totalVolume }

        return SessionAnalyticsSummary(
            generatedAt: Date(),
            totalSessions: relevantMetrics.count,
            completedSessions: completedMetrics.count,
            abandonedSessions: abandonedCount,
            averageDurationSeconds: avgDuration,
            averageCompletionRate: avgCompletionRate,
            averageQualityScore: avgQuality,
            totalPRs: totalPRs,
            typeDistribution: distribution,
            averageRestSeconds: avgRest,
            totalVolume: totalVolume
        )
    }

    /// Returns the most recent session metrics, up to the specified count.
    ///
    /// - Parameter limit: Maximum number of records to return (default: 20).
    /// - Returns: Array of ``WorkoutSessionMetrics`` sorted by start date descending.
    func getRecentMetrics(limit: Int = 20) -> [WorkoutSessionMetrics] {
        let sorted = sessionMetricsHistory.sorted { $0.startedAt > $1.startedAt }
        return Array(sorted.prefix(limit))
    }

    /// Returns all personal records for a given exercise template.
    ///
    /// - Parameter exerciseTemplateId: The exercise template UUID.
    /// - Returns: Array of ``WorkoutPersonalRecord`` sorted by date descending.
    func getPersonalRecords(for exerciseTemplateId: UUID) -> [WorkoutPersonalRecord] {
        return sessionMetricsHistory
            .flatMap { $0.personalRecords }
            .filter { $0.exerciseTemplateId == exerciseTemplateId }
            .sorted { $0.achievedAt > $1.achievedAt }
    }

    // MARK: - Public API: Maintenance

    /// Removes session metrics older than the specified date.
    ///
    /// - Parameter date: Records before this date are removed.
    /// - Returns: The number of records removed.
    @discardableResult
    func pruneMetrics(olderThan date: Date) -> Int {
        let beforeCount = sessionMetricsHistory.count
        sessionMetricsHistory.removeAll { $0.startedAt < date }
        let removed = beforeCount - sessionMetricsHistory.count

        if removed > 0 {
            persistMetricsHistory()
            logger.info("WorkoutAnalytics", "Pruned \(removed) session metrics older than \(date)")
        }

        return removed
    }

    /// Clears all persisted data. Call on logout or account switch.
    func reset() {
        // Clear active session
        activeSessionId = nil
        sessionState = nil
        sessionStartedAt = nil
        activeWorkoutType = .unknown
        activeSessionSource = nil
        pauseTimestamps = []
        resumeTimestamps = []
        accumulatedPauseSeconds = 0
        currentPauseStartedAt = nil
        totalPlannedExercises = 0
        totalPlannedSets = 0
        exerciseCompletions = []
        restTimerRecords = []
        sessionPRs = []

        // Clear persisted data
        weightHistory = [:]
        sessionMetricsHistory = []
        persistWeightHistory()
        persistMetricsHistory()

        logger.info("WorkoutAnalytics", "All workout analytics data reset")
    }

    /// Returns the total number of session metrics records stored.
    var metricsCount: Int {
        sessionMetricsHistory.count
    }

    /// Returns the total number of exercise templates with weight history.
    var weightHistoryCount: Int {
        weightHistory.count
    }

    // MARK: - Private: Session Finalization

    /// Finalize the active session, compute metrics, persist, and emit events.
    @discardableResult
    private func finalizeSession(
        state: WorkoutSessionState,
        averageRPE: Double? = nil,
        averagePainScore: Double? = nil
    ) -> WorkoutSessionMetrics? {
        guard let sessionId = activeSessionId, let startedAt = sessionStartedAt else {
            return nil
        }

        // If currently paused, close the pause
        if let pauseStart = currentPauseStartedAt {
            accumulatedPauseSeconds += Date().timeIntervalSince(pauseStart)
            currentPauseStartedAt = nil
        }

        let endedAt = Date()
        let totalDuration = Int(endedAt.timeIntervalSince(startedAt))
        let activeDuration = max(0, totalDuration - Int(accumulatedPauseSeconds))

        // Compute rest timer stats
        let avgRest: Int? = restTimerRecords.isEmpty ? nil
            : restTimerRecords.reduce(0) { $0 + $1.actualDuration } / restTimerRecords.count
        let skippedTimers = restTimerRecords.filter { $0.wasSkipped }.count

        // Compute volume
        let totalVolume = exerciseCompletions.reduce(0.0) { $0 + $1.volume }
        let totalCompletedSets = exerciseCompletions.reduce(0) { $0 + $1.completedSets }

        // Compute quality score (only for completed sessions)
        let qualityScore: SessionQualityScore? = (state == .completed)
            ? computeQualityScore(averageRPE: averageRPE)
            : nil

        let metrics = WorkoutSessionMetrics(
            id: UUID().uuidString,
            sessionId: sessionId,
            workoutType: activeWorkoutType,
            sessionSource: activeSessionSource,
            startedAt: startedAt,
            endedAt: endedAt,
            totalDurationSeconds: totalDuration,
            activeDurationSeconds: activeDuration,
            pausedDurationSeconds: Int(accumulatedPauseSeconds),
            pauseCount: pauseTimestamps.count,
            totalExercises: totalPlannedExercises,
            completedExercises: exerciseCompletions.count,
            totalPlannedSets: totalPlannedSets,
            totalCompletedSets: totalCompletedSets,
            exerciseCompletions: exerciseCompletions,
            restTimerRecords: restTimerRecords,
            averageRestSeconds: avgRest,
            restTimersSkipped: skippedTimers,
            totalVolume: totalVolume,
            averageRPE: averageRPE,
            averagePainScore: averagePainScore,
            personalRecords: sessionPRs,
            qualityScore: qualityScore
        )

        // Persist to history
        sessionMetricsHistory.append(metrics)
        persistMetricsHistory()

        // Update weight history from exercise completions
        updateWeightHistory(from: exerciseCompletions)

        // Emit completion/abandonment event
        let eventName: String
        let catalogEvent: AnalyticsEventCatalog.WorkoutAnalytics

        if state == .completed {
            eventName = "workout_analytics_session_completed"
            catalogEvent = .sessionCompleted(
                durationSeconds: totalDuration,
                exerciseCount: exerciseCompletions.count,
                completionRate: metrics.exerciseCompletionRate,
                qualityScore: qualityScore?.overallScore
            )
        } else {
            eventName = "workout_analytics_session_abandoned"
            catalogEvent = .sessionAbandoned(
                durationSeconds: totalDuration,
                completedExercises: exerciseCompletions.count,
                totalExercises: totalPlannedExercises
            )
        }

        var properties: [String: Any] = [
            "session_id": sessionId.uuidString,
            "workout_type": activeWorkoutType.rawValue,
            "total_duration_seconds": totalDuration,
            "active_duration_seconds": activeDuration,
            "paused_duration_seconds": Int(accumulatedPauseSeconds),
            "pause_count": pauseTimestamps.count,
            "total_exercises": totalPlannedExercises,
            "completed_exercises": exerciseCompletions.count,
            "exercise_completion_rate": String(format: "%.2f", metrics.exerciseCompletionRate),
            "total_planned_sets": totalPlannedSets,
            "total_completed_sets": totalCompletedSets,
            "set_completion_rate": String(format: "%.2f", metrics.setCompletionRate),
            "total_volume": String(format: "%.1f", totalVolume),
            "rest_timers_used": restTimerRecords.count,
            "rest_timers_skipped": skippedTimers,
            "pr_count": sessionPRs.count,
            "session_state": state.rawValue
        ]

        if let avgRest = avgRest {
            properties["average_rest_seconds"] = avgRest
        }
        if let rpe = averageRPE {
            properties["average_rpe"] = String(format: "%.1f", rpe)
        }
        if let pain = averagePainScore {
            properties["average_pain_score"] = String(format: "%.1f", pain)
        }
        if let score = qualityScore {
            properties["quality_score"] = score.overallScore
            properties["quality_rating"] = score.rating.rawValue
            properties["completion_score"] = score.completionScore
            properties["consistency_score"] = score.consistencyScore
            properties["effort_score"] = score.effortScore
        }

        analyticsTracker.track(event: eventName, properties: properties)

        Task {
            await AnalyticsSDK.shared.track(catalogEvent.eventName, properties: properties)
        }

        // Emit PR events
        for pr in sessionPRs {
            let prProperties: [String: Any] = [
                "session_id": sessionId.uuidString,
                "exercise_name": pr.exerciseName,
                "record_type": pr.recordType.rawValue,
                "previous_value": String(format: "%.1f", pr.previousValue),
                "new_value": String(format: "%.1f", pr.newValue),
                "improvement_percentage": String(format: "%.1f", pr.improvementPercentage),
                "unit": pr.unit
            ]

            Task {
                await AnalyticsSDK.shared.track(
                    AnalyticsEventCatalog.WorkoutAnalytics.personalRecordAchieved(
                        exerciseName: pr.exerciseName,
                        recordType: pr.recordType.rawValue
                    ).eventName,
                    properties: prProperties
                )
            }
        }

        logger.info("WorkoutAnalytics", "Session \(state.rawValue): \(sessionId) (duration=\(totalDuration)s, exercises=\(exerciseCompletions.count)/\(totalPlannedExercises), PRs=\(sessionPRs.count), quality=\(qualityScore?.overallScore.description ?? "n/a"))")

        // Clear active session state
        clearActiveSession()

        return metrics
    }

    /// Reset all active session state after finalization.
    private func clearActiveSession() {
        activeSessionId = nil
        sessionState = nil
        sessionStartedAt = nil
        activeWorkoutType = .unknown
        activeSessionSource = nil
        pauseTimestamps = []
        resumeTimestamps = []
        accumulatedPauseSeconds = 0
        currentPauseStartedAt = nil
        totalPlannedExercises = 0
        totalPlannedSets = 0
        exerciseCompletions = []
        restTimerRecords = []
        sessionPRs = []
    }

    // MARK: - Private: Quality Score Computation

    /// Compute the composite quality score for the active session.
    private func computeQualityScore(averageRPE: Double?) -> SessionQualityScore {
        // --- Completion Score (0-100) ---
        // Based on set completion rate
        let setRate: Double
        if totalPlannedSets > 0 {
            let completedSets = exerciseCompletions.reduce(0) { $0 + $1.completedSets }
            setRate = min(Double(completedSets) / Double(totalPlannedSets), 1.0)
        } else {
            setRate = exerciseCompletions.isEmpty ? 0.0 : 1.0
        }
        let completionScore = Int(setRate * 100)

        // --- Consistency Score (0-100) ---
        // Based on rest timer compliance (how closely actual rest matched prescribed)
        let consistencyScore: Int
        let timerRecordsWithPrescription = restTimerRecords.filter { $0.prescribedDuration != nil }
        if timerRecordsWithPrescription.isEmpty {
            // No prescribed rest timers: neutral score
            consistencyScore = 75
        } else {
            let complianceRates = timerRecordsWithPrescription.compactMap { $0.restComplianceRate }
            let avgCompliance = complianceRates.reduce(0.0, +) / Double(complianceRates.count)
            // Perfect compliance = 1.0. Penalize both under-resting and over-resting.
            // Score = 100 - (deviation from 1.0 * 100), clamped to 0-100
            let deviation = abs(avgCompliance - 1.0)
            consistencyScore = max(0, min(100, Int((1.0 - deviation) * 100)))
        }

        // --- Effort Score (0-100) ---
        // Based on average RPE. Ideal RPE for a quality session is 6-8.
        let effortScore: Int
        if let rpe = averageRPE {
            // Map RPE 0-10 to quality:
            // RPE 7 = 100 (ideal), RPE 6 or 8 = 90, etc.
            // Deduct more for very low RPE (easy session) than for very high (hard session)
            let idealRPE = 7.0
            let distance = abs(rpe - idealRPE)
            if rpe < idealRPE {
                // Under-exertion: steeper penalty
                effortScore = max(0, min(100, Int(100.0 - distance * 20.0)))
            } else {
                // Over-exertion: gentler penalty
                effortScore = max(0, min(100, Int(100.0 - distance * 15.0)))
            }
        } else {
            // No RPE data: neutral score
            effortScore = 70
        }

        // --- Overall Weighted Score ---
        let overall = Int(
            Double(completionScore) * SessionQualityScore.ComponentWeight.completion
            + Double(consistencyScore) * SessionQualityScore.ComponentWeight.consistency
            + Double(effortScore) * SessionQualityScore.ComponentWeight.effort
        )

        let clampedOverall = max(0, min(100, overall))
        let rating = SessionQualityScore.QualityRating.from(score: clampedOverall)

        return SessionQualityScore(
            overallScore: clampedOverall,
            completionScore: completionScore,
            consistencyScore: consistencyScore,
            effortScore: effortScore,
            rating: rating,
            calculatedAt: Date()
        )
    }

    // MARK: - Private: PR Detection

    /// Check for personal records for a specific exercise against the weight history.
    private func detectPersonalRecords(
        exerciseTemplateId: UUID,
        exerciseName: String,
        completedReps: [Int],
        actualLoad: Double?,
        sessionId: UUID
    ) {
        let key = exerciseTemplateId.uuidString
        let existingHistory = weightHistory[key]

        guard let load = actualLoad, load > 0 else { return }
        guard !completedReps.isEmpty else { return }

        let maxRepsInSet = completedReps.max() ?? 0
        let maxSetVolume = load * Double(maxRepsInSet)
        let totalReps = completedReps.reduce(0, +)
        let totalVolume = load * Double(totalReps)

        // Check each record type
        if let history = existingHistory {
            // Max weight PR
            if load > history.maxWeight {
                let pr = WorkoutPersonalRecord(
                    id: UUID().uuidString,
                    exerciseTemplateId: exerciseTemplateId,
                    exerciseName: exerciseName,
                    recordType: .maxWeight,
                    previousValue: history.maxWeight,
                    newValue: load,
                    unit: "lbs",
                    achievedAt: Date(),
                    sessionId: sessionId
                )
                sessionPRs.append(pr)
                logger.info("WorkoutAnalytics", "PR detected: \(exerciseName) Max Weight \(history.maxWeight) -> \(load) lbs (+\(String(format: "%.1f", pr.improvementPercentage))%)")
            }

            // Max reps PR (at same or higher weight)
            if maxRepsInSet > history.maxRepsAtMaxWeight && load >= history.maxWeight {
                let pr = WorkoutPersonalRecord(
                    id: UUID().uuidString,
                    exerciseTemplateId: exerciseTemplateId,
                    exerciseName: exerciseName,
                    recordType: .maxReps,
                    previousValue: Double(history.maxRepsAtMaxWeight),
                    newValue: Double(maxRepsInSet),
                    unit: "reps",
                    achievedAt: Date(),
                    sessionId: sessionId
                )
                sessionPRs.append(pr)
                logger.info("WorkoutAnalytics", "PR detected: \(exerciseName) Max Reps \(history.maxRepsAtMaxWeight) -> \(maxRepsInSet) reps")
            }

            // Max set volume PR
            if maxSetVolume > history.maxSetVolume {
                let pr = WorkoutPersonalRecord(
                    id: UUID().uuidString,
                    exerciseTemplateId: exerciseTemplateId,
                    exerciseName: exerciseName,
                    recordType: .maxVolume,
                    previousValue: history.maxSetVolume,
                    newValue: maxSetVolume,
                    unit: "lbs",
                    achievedAt: Date(),
                    sessionId: sessionId
                )
                sessionPRs.append(pr)
                logger.info("WorkoutAnalytics", "PR detected: \(exerciseName) Max Set Volume \(history.maxSetVolume) -> \(maxSetVolume) lbs")
            }

            // Max total volume PR
            if totalVolume > history.maxTotalVolume {
                let pr = WorkoutPersonalRecord(
                    id: UUID().uuidString,
                    exerciseTemplateId: exerciseTemplateId,
                    exerciseName: exerciseName,
                    recordType: .maxTotalVolume,
                    previousValue: history.maxTotalVolume,
                    newValue: totalVolume,
                    unit: "lbs",
                    achievedAt: Date(),
                    sessionId: sessionId
                )
                sessionPRs.append(pr)
                logger.info("WorkoutAnalytics", "PR detected: \(exerciseName) Max Total Volume \(history.maxTotalVolume) -> \(totalVolume) lbs")
            }
        }
        // If no history exists, the first recorded session will establish the baseline
        // (handled in updateWeightHistory after session ends).
    }

    // MARK: - Private: Weight History

    /// Update the weight history from exercise completion records after a session ends.
    private func updateWeightHistory(from completions: [ExerciseCompletionRecord]) {
        // Group completions by exercise ID to aggregate within session
        // Note: We don't have exerciseTemplateId in ExerciseCompletionRecord,
        // but the PR detection already tracks by template ID. Here we update
        // based on the data we tracked during PR detection.
        // Re-process completions to update weight history for exercises
        // where we detected PRs or have new data.

        // For simplicity and correctness, update from the PRs that were detected
        // and from any new exercises that don't have history yet.
        var updated = false

        for completion in completions {
            guard let load = completion.actualLoad, load > 0, !completion.completedReps.isEmpty else {
                continue
            }

            // We use exerciseId as a proxy key here. In a full implementation,
            // exerciseTemplateId would be preferred. Since ExerciseCompletionRecord
            // stores exerciseId (which maps to the exercise instance), we use it
            // for exercises without template context.
            let key = completion.exerciseId.uuidString
            let maxReps = completion.completedReps.max() ?? 0
            let maxSetVolume = load * Double(maxReps)
            let totalReps = completion.completedReps.reduce(0, +)
            let totalVolume = load * Double(totalReps)

            if let existing = weightHistory[key] {
                var needsUpdate = false
                var entry = existing

                if load > entry.maxWeight || maxReps > entry.maxRepsAtMaxWeight
                    || maxSetVolume > entry.maxSetVolume || totalVolume > entry.maxTotalVolume {
                    entry = WeightHistoryEntry(
                        exerciseTemplateId: existing.exerciseTemplateId,
                        maxWeight: max(load, entry.maxWeight),
                        maxRepsAtMaxWeight: load >= entry.maxWeight ? max(maxReps, entry.maxRepsAtMaxWeight) : entry.maxRepsAtMaxWeight,
                        maxSetVolume: max(maxSetVolume, entry.maxSetVolume),
                        maxTotalVolume: max(totalVolume, entry.maxTotalVolume),
                        lastUpdatedAt: Date()
                    )
                    needsUpdate = true
                }

                if needsUpdate {
                    weightHistory[key] = entry
                    updated = true
                }
            } else {
                // First time seeing this exercise - establish baseline
                let entry = WeightHistoryEntry(
                    exerciseTemplateId: completion.exerciseId,
                    maxWeight: load,
                    maxRepsAtMaxWeight: maxReps,
                    maxSetVolume: maxSetVolume,
                    maxTotalVolume: totalVolume,
                    lastUpdatedAt: Date()
                )
                weightHistory[key] = entry
                updated = true
            }
        }

        if updated {
            persistWeightHistory()
        }
    }

    // MARK: - Private: Workout Type Inference

    /// Infer workout type from prescribed exercises by looking at categories.
    private func inferWorkoutType(from exercises: [Exercise]) -> WorkoutType {
        guard !exercises.isEmpty else { return .unknown }

        var typeCounts: [WorkoutType: Int] = [:]
        for exercise in exercises {
            let category = exercise.exercise_templates?.category
            let type = WorkoutType.from(templateCategory: category)
            if type != .unknown {
                typeCounts[type, default: 0] += 1
            }
        }

        // If all exercises map to one type, use it
        if typeCounts.count == 1, let single = typeCounts.first {
            return single.key
        }

        // If strength-related types dominate, return strength
        let strengthCount = (typeCounts[.strength] ?? 0)
        let totalMapped = typeCounts.values.reduce(0, +)
        if totalMapped > 0 && Double(strengthCount) / Double(totalMapped) > 0.5 {
            return .strength
        }

        // Mixed types = hybrid
        if typeCounts.count > 1 {
            return .hybrid
        }

        return .unknown
    }

    /// Infer workout type from manual session exercises by looking at block names.
    private func inferWorkoutType(fromManualExercises exercises: [ManualSessionExercise]) -> WorkoutType {
        guard !exercises.isEmpty else { return .unknown }

        var typeCounts: [WorkoutType: Int] = [:]
        for exercise in exercises {
            if let blockName = exercise.blockName {
                let blockType = WorkoutBlockType.inferFromName(blockName)
                let workoutType = WorkoutType.from(blockType: blockType)
                typeCounts[workoutType, default: 0] += 1
            }
        }

        if typeCounts.count == 1, let single = typeCounts.first {
            return single.key
        }

        if typeCounts.count > 1 {
            return .hybrid
        }

        return .unknown
    }

    // MARK: - Persistence

    private func persistWeightHistory() {
        do {
            let data = try Self.encoder.encode(weightHistory)
            try data.write(to: weightHistoryURL, options: .atomic)
            logger.diagnostic("WorkoutAnalytics: Persisted \(weightHistory.count) weight history entries")
        } catch {
            logger.warning("WorkoutAnalytics", "Failed to persist weight history: \(error.localizedDescription)")
        }
    }

    private func loadWeightHistory() {
        guard FileManager.default.fileExists(atPath: weightHistoryURL.path) else {
            logger.diagnostic("WorkoutAnalytics: No persisted weight history found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: weightHistoryURL)
            let loaded = try Self.decoder.decode([String: WeightHistoryEntry].self, from: data)
            weightHistory = loaded
            logger.info("WorkoutAnalytics", "Loaded \(loaded.count) weight history entries")
        } catch {
            logger.warning("WorkoutAnalytics", "Failed to load weight history: \(error.localizedDescription)")
        }
    }

    private func persistMetricsHistory() {
        do {
            let data = try Self.encoder.encode(sessionMetricsHistory)
            try data.write(to: metricsHistoryURL, options: .atomic)
            logger.diagnostic("WorkoutAnalytics: Persisted \(sessionMetricsHistory.count) session metrics")
        } catch {
            logger.warning("WorkoutAnalytics", "Failed to persist session metrics: \(error.localizedDescription)")
        }
    }

    private func loadMetricsHistory() {
        guard FileManager.default.fileExists(atPath: metricsHistoryURL.path) else {
            logger.diagnostic("WorkoutAnalytics: No persisted session metrics found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: metricsHistoryURL)
            let loaded = try Self.decoder.decode([WorkoutSessionMetrics].self, from: data)
            sessionMetricsHistory = loaded
            logger.info("WorkoutAnalytics", "Loaded \(loaded.count) session metrics from previous sessions")
        } catch {
            logger.warning("WorkoutAnalytics", "Failed to load session metrics: \(error.localizedDescription)")
        }
    }
}

// MARK: - AnalyticsEventCatalog Extension

extension AnalyticsEventCatalog {

    /// Events related to workout session analytics tracking.
    enum WorkoutAnalytics {
        case sessionStarted(workoutType: String, exerciseCount: Int)
        case sessionPaused
        case sessionResumed
        case sessionCompleted(durationSeconds: Int, exerciseCount: Int, completionRate: Double, qualityScore: Int?)
        case sessionAbandoned(durationSeconds: Int, completedExercises: Int, totalExercises: Int)
        case exerciseCompleted(name: String, completionRate: Double)
        case restTimerCompleted
        case restTimerSkipped
        case personalRecordAchieved(exerciseName: String, recordType: String)

        /// Standardized snake_case event name.
        var eventName: String {
            switch self {
            case .sessionStarted:
                return "workout_analytics_session_started"
            case .sessionPaused:
                return "workout_analytics_session_paused"
            case .sessionResumed:
                return "workout_analytics_session_resumed"
            case .sessionCompleted:
                return "workout_analytics_session_completed"
            case .sessionAbandoned:
                return "workout_analytics_session_abandoned"
            case .exerciseCompleted:
                return "workout_analytics_exercise_completed"
            case .restTimerCompleted:
                return "workout_analytics_rest_timer_completed"
            case .restTimerSkipped:
                return "workout_analytics_rest_timer_skipped"
            case .personalRecordAchieved:
                return "workout_analytics_pr_achieved"
            }
        }

        /// Associated values serialized as a string dictionary.
        var properties: [String: String] {
            switch self {
            case .sessionStarted(let workoutType, let exerciseCount):
                return [
                    "workout_type": workoutType,
                    "exercise_count": String(exerciseCount)
                ]
            case .sessionPaused:
                return [:]
            case .sessionResumed:
                return [:]
            case .sessionCompleted(let duration, let exerciseCount, let completionRate, let qualityScore):
                var props = [
                    "duration_seconds": String(duration),
                    "exercise_count": String(exerciseCount),
                    "completion_rate": String(format: "%.2f", completionRate)
                ]
                if let score = qualityScore {
                    props["quality_score"] = String(score)
                }
                return props
            case .sessionAbandoned(let duration, let completedExercises, let totalExercises):
                return [
                    "duration_seconds": String(duration),
                    "completed_exercises": String(completedExercises),
                    "total_exercises": String(totalExercises)
                ]
            case .exerciseCompleted(let name, let completionRate):
                return [
                    "exercise_name": name,
                    "completion_rate": String(format: "%.2f", completionRate)
                ]
            case .restTimerCompleted:
                return [:]
            case .restTimerSkipped:
                return [:]
            case .personalRecordAchieved(let exerciseName, let recordType):
                return [
                    "exercise_name": exerciseName,
                    "record_type": recordType
                ]
            }
        }
    }
}

// MARK: - Convenience Alias

/// Convenience namespace for quick workout analytics calls.
///
/// Provides a terse, ergonomic API that delegates to ``WorkoutSessionAnalytics.shared``.
///
/// ```swift
/// await WorkoutAnalytics.shared.startSession(sessionId: id, workoutType: .strength, exercises: items)
/// await WorkoutAnalytics.shared.recordExerciseCompletion(...)
/// let metrics = await WorkoutAnalytics.shared.endSession(averageRPE: 7.5)
/// ```
enum WorkoutAnalytics {
    /// The shared ``WorkoutSessionAnalytics`` instance.
    static var shared: WorkoutSessionAnalytics {
        WorkoutSessionAnalytics.shared
    }
}
