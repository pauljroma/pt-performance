//
//  IntervalTimerService.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 9 (Interval Timer Service)
//  Service for interval timer operations and countdown logic
//

import Foundation
import Supabase
import AVFoundation
import UIKit

/// Service for managing interval timers with precise countdown logic
@MainActor
class IntervalTimerService: ObservableObject {
    // MARK: - Singleton

    static let shared = IntervalTimerService()

    nonisolated(unsafe) private let client: PTSupabaseClient

    // MARK: - Published State

    /// Current timer state (idle, running, paused, completed)
    @Published var state: TimerState = .idle

    /// Current round number (1-based)
    @Published var currentRound: Int = 0

    /// Current phase (work or rest)
    @Published var currentPhase: TimerPhase = .work

    /// Time remaining in current phase (seconds with 0.1s precision)
    @Published var timeRemaining: Double = 0

    /// Total elapsed time for session (seconds)
    @Published var totalElapsed: Double = 0

    /// Total paused seconds (integer seconds)
    @Published var pausedSeconds: Int = 0

    /// Active workout session
    @Published var activeSession: WorkoutTimer?

    /// Active template being used
    @Published var activeTemplate: IntervalTemplate?

    // MARK: - Private State

    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var pauseStartTime: Date?

    // MARK: - Initialization

    private init(client: PTSupabaseClient = .shared) {
        self.client = client
        setupAudio()
    }

    // MARK: - Timer Phase

    /// Timer phase (work, rest, or break)
    enum TimerPhase {
        case work
        case rest
        case `break`

        var displayName: String {
            switch self {
            case .work: return "WORK"
            case .rest: return "REST"
            case .break: return "BREAK"
            }
        }

        var color: String {
            switch self {
            case .work: return "red"
            case .rest: return "green"
            case .break: return "blue"
            }
        }
    }

    // MARK: - Fetch Timer Presets

    /// Fetch timer presets by category
    func fetchPresets(category: TimerCategory? = nil) async throws -> [TimerPreset] {
        // BUILD 133: Enhanced logging for timer preset loading
        let categoryFilter = category?.rawValue ?? "all"
        DebugLogger.shared.logQuery(
            table: "timer_presets",
            query: "SELECT * WHERE category = ? ORDER BY name",
            params: ["category": categoryFilter]
        )

        var query = client.client
            .from("timer_presets")
            .select()

        if let category = category {
            query = query.eq("category", value: category.rawValue)
        }

        DebugLogger.shared.info("TIMER_DATA", "Executing timer_presets query...")

        let response = try await query
            .order("name", ascending: true)
            .execute()

        DebugLogger.shared.info("TIMER_DATA", "Response received: \(response.data.count) bytes")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // BUILD 133: Try to decode with detailed error logging
        do {
            let presets = try decoder.decode([TimerPreset].self, from: response.data)
            DebugLogger.shared.success("TIMER_DATA", "Decoded \(presets.count) timer presets successfully")
            return presets
        } catch let decodingError as DecodingError {
            // Log raw JSON on decoding failure
            let rawJSON = String(data: response.data, encoding: .utf8) ?? "Unable to decode as UTF-8"
            DebugLogger.shared.error("TIMER_DATA", """
                DECODING ERROR for timer_presets:
                Raw JSON: \(rawJSON)

                Decoding error: \(decodingError)
                """)

            // Log specific error details
            switch decodingError {
            case .typeMismatch(let type, let context):
                DebugLogger.shared.error("TIMER_DATA", """
                    Type Mismatch:
                    Expected: \(type)
                    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                    Description: \(context.debugDescription)
                    """)
            case .keyNotFound(let key, let context):
                DebugLogger.shared.error("TIMER_DATA", """
                    Key Not Found:
                    Missing key: \(key.stringValue)
                    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))
                    """)
            default:
                DebugLogger.shared.error("TIMER_DATA", "Other decoding error: \(decodingError)")
            }

            throw decodingError
        }
    }

    // MARK: - Fetch Templates

    /// Fetch interval templates (user-created or public)
    func fetchTemplates(publicOnly: Bool = false) async throws -> [IntervalTemplate] {
        var query = client.client
            .from("interval_templates")
            .select()

        if publicOnly {
            query = query.eq("is_public", value: true)
        }

        let response = try await query
            .order("name", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([IntervalTemplate].self, from: response.data)
    }

    // MARK: - Create Custom Template

    /// Create a custom interval template
    func createTemplate(
        name: String,
        type: TimerType,
        workSeconds: Int,
        restSeconds: Int,
        rounds: Int,
        cycles: Int = 1,
        isPublic: Bool = false,
    ) async throws -> IntervalTemplate {
        // Validate input
        guard workSeconds > 0 else {
            throw TimerError.invalidWorkDuration
        }
        guard restSeconds >= 0 else {
            throw TimerError.invalidRestDuration
        }
        guard rounds > 0 else {
            throw TimerError.invalidRounds
        }

        guard let userId = client.currentUser?.id else {
            throw TimerError.notAuthenticated
        }

        let input = CreateIntervalTemplateInput(
            name: name,
            type: type,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            rounds: rounds,
            cycles: cycles,
            createdBy: userId,
            isPublic: isPublic,
        )

        let response = try await client.client
            .from("interval_templates")
            .insert(input)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(IntervalTemplate.self, from: response.data)
    }

    // MARK: - Start Timer

    /// Start a timer session with a template
    func startTimer(template: IntervalTemplate, patientId: UUID) async throws {
        // Diagnostic logging
        DebugLogger.shared.info("TIMER_START", """
            Starting timer attempt:
            Current state: \(state)
            Active session: \(activeSession?.id.uuidString ?? "nil")
            Active template: \(activeTemplate?.id.uuidString ?? "nil")
            Has active timer: \(timer != nil)
            """)

        // Debounce: If we just started a timer with this exact configuration, ignore duplicate call
        // Compare by configuration (type, work, rest, rounds) not ID, since presets create new template instances
        if state == .running,
           let activeTemplate = activeTemplate,
           activeTemplate.type == template.type &&
           activeTemplate.workSeconds == template.workSeconds &&
           activeTemplate.restSeconds == template.restSeconds &&
           activeTemplate.rounds == template.rounds {
            DebugLogger.shared.warning("TIMER_START", "Ignoring duplicate start call for same template configuration (debouncing)")
            return
        }

        // Cancel any existing timer and reset state
        if timer == nil {
            // No timer running - safe to reset
            DebugLogger.shared.info("TIMER_START", "No active countdown timer - forcing state to .idle")
            state = .idle
            activeSession = nil
            activeTemplate = nil
        } else if state != .running {
            // Timer exists but state is wrong - clean up
            DebugLogger.shared.warning("TIMER_START", "Found orphaned timer - cleaning up")
            timer?.invalidate()
            timer = nil
            state = .idle
            activeSession = nil
            activeTemplate = nil
        }

        // Allow starting a new timer if idle or if previous timer completed
        guard state == .idle || state == .completed else {
            DebugLogger.shared.error("TIMER_START", "Guard failed - state is \(state), not .idle or .completed")
            throw TimerError.timerAlreadyRunning
        }

        // Create workout session in database
        let sessionInput = CreateWorkoutTimerInput(
            patientId: patientId,
            templateId: nil,  // NULL - template is ephemeral from preset
            startedAt: Date(),
            roundsCompleted: 0,
            pausedSeconds: 0,
        )

        let response = try await client.client
            .from("workout_timers")
            .insert(sessionInput)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(WorkoutTimer.self, from: response.data)

        // Initialize timer state
        activeSession = session
        activeTemplate = template
        currentRound = 1
        currentPhase = .work
        timeRemaining = Double(template.workSeconds)
        totalElapsed = 0
        pausedSeconds = 0
        state = .running

        // Start countdown
        startCountdown()

        // Play start sound and haptic
        playSound(.start)
        triggerHaptic(.medium)
    }

    // MARK: - Countdown Logic

    /// Start the countdown timer with 0.1s precision
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    /// Tick function called every 0.1 seconds
    private func tick() {
        guard state == .running, let template = activeTemplate else { return }

        // Decrement time
        timeRemaining -= 0.1
        totalElapsed += 0.1

        // Round to avoid floating point errors
        timeRemaining = (timeRemaining * 10).rounded() / 10

        // Check if phase complete
        if timeRemaining <= 0 {
            advancePhase(template: template)
        }

        // Audio cues at specific times
        let roundedTime = Int(timeRemaining.rounded())
        if roundedTime == 3 && timeRemaining > 2.9 && timeRemaining < 3.1 {
            playSound(.countdown)
        }
    }

    /// Advance to next phase (work -> rest -> next round)
    private func advancePhase(template: IntervalTemplate) {
        switch currentPhase {
        case .work:
            // Work phase done, move to rest
            currentPhase = .rest
            timeRemaining = Double(template.restSeconds)
            playSound(.rest)
            triggerHaptic(.light)

        case .rest:
            // Rest phase done, check if more rounds
            if currentRound < template.rounds {
                // Next round
                currentRound += 1
                currentPhase = .work
                timeRemaining = Double(template.workSeconds)
                playSound(.work)
                triggerHaptic(.medium)
            } else {
                // All rounds complete
                Task {
                    await completeSession()
                }
            }

        case .break:
            // Cycle break done, start next cycle
            currentPhase = .work
            timeRemaining = Double(template.workSeconds)
            playSound(.work)
            triggerHaptic(.medium)
        }
    }

    // MARK: - Pause/Resume

    /// Pause the timer
    func pauseTimer() {
        guard state == .running else { return }

        state = .paused
        pauseStartTime = Date()
        timer?.invalidate()
        timer = nil

        playSound(.pause)
        triggerHaptic(.light)
    }

    /// Resume the timer
    func resumeTimer() {
        guard state == .paused else { return }

        // Calculate paused duration
        if let pauseStart = pauseStartTime {
            let pauseDuration = Int(Date().timeIntervalSince(pauseStart))
            pausedSeconds += pauseDuration
        }

        state = .running
        pauseStartTime = nil
        startCountdown()

        playSound(.resume)
        triggerHaptic(.light)
    }

    // MARK: - Complete Session

    /// Complete the timer session and save to database
    func completeSession() async {
        state = .completed
        timer?.invalidate()
        timer = nil

        playSound(.complete)
        triggerHaptic(.success)

        // Update database
        guard let session = activeSession, let _ = activeTemplate else { return }

        do {
            // Update workout_timers record
            let updateInput = UpdateWorkoutTimerInput(
                completedAt: Date(),
                roundsCompleted: currentRound,
                pausedSeconds: pausedSeconds,
            )

            _ = try await client.client
                .from("workout_timers")
                .update(updateInput)
                .eq("id", value: session.id.uuidString)
                .execute()

            // Log session via database function
            // Use session.templateId (null for ephemeral presets) instead of template.id
            // Note: For ephemeral templates from presets, templateId is nil
            if let templateId = session.templateId {
                _ = try await client.client.rpc(
                    "log_timer_session",
                    params: [
                        "p_patient_id": session.patientId.uuidString,
                        "p_template_id": templateId.uuidString,
                        "p_duration": String(Int(totalElapsed))
                    ]
                ).execute()
            } else {
                // Skip logging for ephemeral templates (from presets)
                DebugLogger.shared.info("TIMER", "Skipping log_timer_session for ephemeral template")
            }

            DebugLogger.shared.success("TIMER", "Timer session completed and logged")
        } catch {
            DebugLogger.shared.error("TIMER", "Failed to complete session: \(error.localizedDescription)")
            DebugLogger.shared.error("TIMER", "Error type: \(type(of: error))")
        }
    }

    /// Cancel the timer without saving
    func cancelTimer() {
        state = .idle
        timer?.invalidate()
        timer = nil
        activeSession = nil
        activeTemplate = nil
        currentRound = 0
        currentPhase = .work
        timeRemaining = 0
        totalElapsed = 0
        pausedSeconds = 0
    }

    // MARK: - Audio Setup

    /// Setup audio session for timer sounds
    nonisolated private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            DebugLogger.shared.warning("TIMER", "Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio & Haptics

    /// Sound type enumeration
    enum SoundType: String {
        case start = "timer_start"
        case work = "timer_work"
        case rest = "timer_rest"
        case pause = "timer_pause"
        case resume = "timer_resume"
        case complete = "timer_complete"
        case countdown = "timer_countdown"
        case phaseComplete = "timer_phase_complete"
    }

    /// Play a sound (uses system sounds as fallback)
    private func playSound(_ type: SoundType) {
        // Try to load custom sound file
        if let soundURL = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
                return
            } catch {
                DebugLogger.shared.warning("TIMER", "Failed to play custom sound: \(error.localizedDescription)")
            }
        }

        // Fallback to system sounds
        let systemSound: SystemSoundID
        switch type {
        case .start:
            systemSound = 1073  // SMS Received
        case .work:
            systemSound = 1073  // SMS Received
        case .rest:
            systemSound = 1052  // Short beep
        case .pause:
            systemSound = 1104  // Short low beep
        case .resume:
            systemSound = 1073  // SMS Received
        case .complete:
            systemSound = 1025  // SMS Alert
        case .countdown:
            systemSound = 1057  // Tock
        case .phaseComplete:
            systemSound = 1052  // Short beep
        }

        AudioServicesPlaySystemSound(systemSound)
    }

    /// Trigger haptic feedback
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger success haptic (notification style)
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Fetch Timer History

    /// Fetch timer history for a patient
    func fetchTimerHistory(
        for patientId: UUID,
        limit: Int = 20,
    ) async throws -> [WorkoutTimer] {
        let response = try await client.client
            .from("workout_timers")
            .select()
            .eq("patient_id", value: patientId.uuidString)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutTimer].self, from: response.data)
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Timer Errors

/// Errors for timer operations
enum TimerError: LocalizedError {
    case invalidWorkDuration
    case invalidRestDuration
    case invalidRounds
    case sessionNotFound
    case timerAlreadyRunning
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidWorkDuration:
            return "Work duration must be greater than 0"
        case .invalidRestDuration:
            return "Rest duration must be 0 or greater"
        case .invalidRounds:
            return "Rounds must be greater than 0"
        case .sessionNotFound:
            return "Timer session not found"
        case .timerAlreadyRunning:
            return "Timer is already running"
        case .notAuthenticated:
            return "User must be authenticated"
        }
    }
}
