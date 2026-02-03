//
//  ActiveTimerViewModel.swift
//  PTPerformance
//
//  ViewModel for active timer display with real-time countdown updates
//

import SwiftUI

/// ViewModel for active timer full-screen countdown display
/// Binds to IntervalTimerService for real-time updates (0.1s precision)
@MainActor
class ActiveTimerViewModel: ObservableObject {
    // MARK: - Dependencies

    private let timerService: IntervalTimerService
    private let backgroundManager: BackgroundTimerManager

    // MARK: - Published State (Bound from IntervalTimerService)

    /// Current timer state (idle, running, paused, completed)
    @Published var state: TimerState = .idle

    /// Current round number (1-based)
    @Published var currentRound: Int = 0

    /// Total rounds in template
    @Published var totalRounds: Int = 0

    /// Current phase (work, rest, or break)
    @Published var currentPhase: IntervalTimerService.TimerPhase = .work

    /// Time remaining in current phase (seconds with 0.1s precision)
    @Published var timeRemaining: Double = 0

    /// Total elapsed time for session (seconds)
    @Published var totalElapsed: Double = 0

    // MARK: - Template Info

    /// Active template name
    @Published var templateName: String = ""

    /// Template type (Tabata, EMOM, etc.)
    @Published var templateType: TimerType = .custom

    /// Work interval duration in seconds
    @Published var workSeconds: Int = 0

    /// Rest interval duration in seconds
    @Published var restSeconds: Int = 0

    // MARK: - Computed Properties

    /// Formatted time remaining with tenths (MM:SS.T)
    var formattedTimeRemaining: String {
        formatTime(timeRemaining)
    }

    /// Formatted total elapsed time (MM:SS)
    var formattedTotalElapsed: String {
        formatTimeWithoutTenths(totalElapsed)
    }

    /// Round progress as fraction (0.0 to 1.0)
    var roundProgress: Double {
        guard totalRounds > 0 else { return 0 }
        return Double(currentRound) / Double(totalRounds)
    }

    /// Round progress as percentage string (e.g., "38%")
    var progressPercentage: String {
        "\(Int(roundProgress * 100))%"
    }

    /// Phase color for UI display
    var phaseColor: Color {
        switch currentPhase {
        case .work:
            return .red
        case .rest:
            return .green
        case .break:
            return .blue
        }
    }

    /// Phase display name (WORK, REST, BREAK)
    var phaseDisplayName: String {
        currentPhase.displayName
    }

    /// Whether timer can be paused
    var canPause: Bool {
        state == .running
    }

    /// Whether timer can be resumed
    var canResume: Bool {
        state == .paused
    }

    /// Whether timer is currently active (running or paused)
    var isActive: Bool {
        state == .running || state == .paused
    }

    /// Round status text (e.g., "Round 3 of 8")
    var roundStatusText: String {
        guard totalRounds > 0 else { return "" }
        return "Round \(currentRound) of \(totalRounds)"
    }

    // MARK: - Initialization

    @MainActor init(
        timerService: IntervalTimerService? = nil,
        backgroundManager: BackgroundTimerManager? = nil
    ) {
        self.timerService = timerService ?? .shared
        self.backgroundManager = backgroundManager ?? .shared
    }

    // MARK: - Load Active Timer

    /// Load active timer state from IntervalTimerService
    /// Called when view appears or resumes from background
    func loadActiveTimer() {
        syncState()
    }

    // MARK: - Update (called every 0.1s from view)

    /// Update state from timer service
    /// Should be called every 0.1 seconds by the view for real-time display
    func update() {
        syncState()
    }

    // MARK: - Private State Sync

    /// Sync all state from timer service to published properties
    private func syncState() {
        state = timerService.state
        currentRound = timerService.currentRound
        currentPhase = timerService.currentPhase
        timeRemaining = timerService.timeRemaining
        totalElapsed = timerService.totalElapsed

        if let template = timerService.activeTemplate {
            templateName = template.name
            templateType = template.type
            totalRounds = template.rounds
            workSeconds = template.workSeconds
            restSeconds = template.restSeconds
        }
    }

    // MARK: - Pause/Resume Controls

    /// Pause the timer
    func pauseTimer() {
        guard canPause else { return }
        timerService.pauseTimer()
        state = .paused
    }

    /// Resume the timer
    func resumeTimer() {
        guard canResume else { return }
        timerService.resumeTimer()
        state = .running
    }

    // MARK: - Stop Timer

    /// Stop the timer and complete session
    /// Saves session to database
    func stopTimer() async {
        await timerService.completeSession()
        state = .completed
    }

    /// Cancel the timer without saving
    func cancelTimer() {
        timerService.cancelTimer()
        state = .idle
    }

    // MARK: - Time Formatting

    /// Format time with tenths of seconds (MM:SS.T)
    /// Used for countdown display
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, secs, tenths)
    }

    /// Format time without tenths (MM:SS)
    /// Used for total elapsed display
    private func formatTimeWithoutTenths(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Background Support

    /// Handle app entering background
    /// Saves timer state and schedules notifications
    func handleAppWillBackground() {
        backgroundManager.handleAppDidEnterBackground(timerService: timerService)
    }

    /// Handle app returning to foreground
    /// Restores timer state and clears notifications
    func handleAppWillForeground() async {
        await backgroundManager.handleAppWillEnterForeground(timerService: timerService)
        loadActiveTimer()
    }
}

// MARK: - Preview Support

extension ActiveTimerViewModel {
    /// Preview instance for SwiftUI previews
    static var preview: ActiveTimerViewModel {
        let vm = ActiveTimerViewModel()

        // Mock data for preview
        vm.state = .running
        vm.currentRound = 3
        vm.totalRounds = 8
        vm.currentPhase = .work
        vm.timeRemaining = 15.5
        vm.totalElapsed = 180.0
        vm.templateName = "Classic Tabata"
        vm.templateType = .tabata

        return vm
    }

    /// Paused preview instance
    static var previewPaused: ActiveTimerViewModel {
        let vm = ActiveTimerViewModel()

        // Mock paused state
        vm.state = .paused
        vm.currentRound = 5
        vm.totalRounds = 8
        vm.currentPhase = .rest
        vm.timeRemaining = 7.3
        vm.totalElapsed = 245.0
        vm.templateName = "EMOM 10"
        vm.templateType = .emom

        return vm
    }

    /// Completed preview instance
    static var previewCompleted: ActiveTimerViewModel {
        let vm = ActiveTimerViewModel()

        // Mock completed state
        vm.state = .completed
        vm.currentRound = 8
        vm.totalRounds = 8
        vm.currentPhase = .rest
        vm.timeRemaining = 0
        vm.totalElapsed = 360.0
        vm.templateName = "5 Min AMRAP"
        vm.templateType = .amrap

        return vm
    }
}
