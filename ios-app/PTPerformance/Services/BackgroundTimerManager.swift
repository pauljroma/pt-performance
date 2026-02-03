//
//  BackgroundTimerManager.swift
//  PTPerformance
//
//  Background timer continuation with notifications
//

import Foundation
import BackgroundTasks
import UserNotifications

/// Manages timer continuation when app is backgrounded or screen locked
/// Handles background tasks, local notifications, and state persistence
@MainActor
class BackgroundTimerManager: ObservableObject {
    static let shared = BackgroundTimerManager()

    private let backgroundTaskIdentifier = "com.ptperformance.timer.background"

    @Published var hasPermission: Bool = false

    private init() {
        registerBackgroundTask()
    }

    // MARK: - Background Task Registration

    /// Register background task for timer continuation
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handleBackgroundTask(task: refreshTask)
        }
    }

    /// Handle background task execution
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        // Schedule next background refresh
        scheduleBackgroundRefresh()

        // Mark task complete
        task.setTaskCompleted(success: true)
    }

    /// Schedule next background refresh (max 15 seconds)
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15) // 15 seconds

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            DebugLogger.shared.warning("BackgroundTimerManager", "Background refresh scheduling failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Permissions

    /// Request notification permission from user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                self.hasPermission = granted
            }

            DebugLogger.shared.info("DEBUG", 
                "Notification permission \(granted ? "granted" : "denied")",
            )

            return granted
        } catch {
            DebugLogger.shared.warning("BackgroundTimerManager", "Notification permission request failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule local notifications for timer phases
    /// - Parameters:
    ///   - template: Timer template with work/rest configuration
    ///   - startTime: When the timer started
    func scheduleTimerNotifications(
        template: IntervalTemplate,
        startTime: Date
    ) async throws {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        DebugLogger.shared.info("DEBUG", 
            "Scheduling notifications for \(template.name) - \(template.rounds) rounds",
        )

        var currentTime = startTime

        for round in 1...template.rounds {
            // Work phase notification
            currentTime = currentTime.addingTimeInterval(Double(template.workSeconds))

            let workContent = UNMutableNotificationContent()
            workContent.title = "Round \(round) Work Complete"
            workContent.body = "Starting rest period"
            workContent.sound = .default
            workContent.badge = round as NSNumber

            let workTrigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, currentTime.timeIntervalSinceNow),
                repeats: false
            )

            let workRequest = UNNotificationRequest(
                identifier: "timer_work_\(round)",
                content: workContent,
                trigger: workTrigger
            )

            try await UNUserNotificationCenter.current().add(workRequest)

            // Rest phase notification (if not last round)
            if round < template.rounds {
                currentTime = currentTime.addingTimeInterval(Double(template.restSeconds))

                let restContent = UNMutableNotificationContent()
                restContent.title = "Round \(round) Complete"
                restContent.body = "Starting round \(round + 1)"
                restContent.sound = .default
                restContent.badge = round as NSNumber

                let restTrigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: max(1, currentTime.timeIntervalSinceNow),
                    repeats: false
                )

                let restRequest = UNNotificationRequest(
                    identifier: "timer_rest_\(round)",
                    content: restContent,
                    trigger: restTrigger
                )

                try await UNUserNotificationCenter.current().add(restRequest)
            }
        }

        // Final completion notification
        currentTime = currentTime.addingTimeInterval(Double(template.restSeconds))

        let completeContent = UNMutableNotificationContent()
        completeContent.title = "Workout Complete! 🎉"
        completeContent.body = "\(template.name) finished - \(template.rounds) rounds completed"
        completeContent.sound = .default
        completeContent.badge = 0 // Clear badge

        let completeTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, currentTime.timeIntervalSinceNow),
            repeats: false
        )

        let completeRequest = UNNotificationRequest(
            identifier: "timer_complete",
            content: completeContent,
            trigger: completeTrigger
        )

        try await UNUserNotificationCenter.current().add(completeRequest)

        DebugLogger.shared.info("DEBUG", 
            "Scheduled \((template.rounds * 2) + 1) notifications",
        )
    }

    // MARK: - Timer State Persistence

    /// Codable structure for persisting timer state
    struct TimerState: Codable {
        let templateId: UUID
        let sessionId: UUID
        let currentRound: Int
        let currentPhase: String // "work" or "rest"
        let timeRemaining: Double
        let totalElapsed: Double
        let pausedSeconds: Int
        let startTime: Date
        let templateName: String
        let workSeconds: Int
        let restSeconds: Int
        let totalRounds: Int
    }

    /// Save timer state to UserDefaults
    func saveTimerState(
        templateId: UUID,
        sessionId: UUID,
        currentRound: Int,
        currentPhase: String,
        timeRemaining: Double,
        totalElapsed: Double,
        pausedSeconds: Int,
        startTime: Date,
        templateName: String,
        workSeconds: Int,
        restSeconds: Int,
        totalRounds: Int
    ) {
        let state = TimerState(
            templateId: templateId,
            sessionId: sessionId,
            currentRound: currentRound,
            currentPhase: currentPhase,
            timeRemaining: timeRemaining,
            totalElapsed: totalElapsed,
            pausedSeconds: pausedSeconds,
            startTime: startTime,
            templateName: templateName,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            totalRounds: totalRounds
        )

        do {
            let encoded = try JSONEncoder().encode(state)
            UserDefaults.standard.set(encoded, forKey: "timer_state")

            DebugLogger.shared.info("DEBUG",
                "Saved timer state: Round \(currentRound)/\(totalRounds), Phase: \(currentPhase)",
            )
        } catch {
            DebugLogger.shared.log("Failed to encode timer state for persistence: \(error.localizedDescription)", level: .error)
        }
    }

    /// Restore timer state from UserDefaults
    func restoreTimerState() -> TimerState? {
        guard let data = UserDefaults.standard.data(forKey: "timer_state") else {
            DebugLogger.shared.info("DEBUG",
                "No saved timer state found",
            )
            return nil
        }

        do {
            let state = try JSONDecoder().decode(TimerState.self, from: data)
            DebugLogger.shared.info("DEBUG",
                "Restored timer state: \(state.templateName), Round \(state.currentRound)/\(state.totalRounds)",
            )
            return state
        } catch {
            DebugLogger.shared.log("Failed to decode timer state from persistence: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Clear saved timer state
    func clearTimerState() {
        UserDefaults.standard.removeObject(forKey: "timer_state")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        DebugLogger.shared.info("DEBUG", 
            "Cleared timer state and notifications",
        )
    }

    // MARK: - App Lifecycle Handling

    /// Handle app entering background
    /// - Parameter timerService: The active timer service
    func handleAppDidEnterBackground(timerService: IntervalTimerService) {
        guard let template = timerService.activeTemplate,
              let session = timerService.activeSession,
              timerService.state == .running else {
            DebugLogger.shared.info("DEBUG", 
                "No active timer to persist",
            )
            return
        }

        DebugLogger.shared.info("DEBUG", 
            "App entering background with active timer",
        )

        // Save current state
        saveTimerState(
            templateId: template.id,
            sessionId: session.id,
            currentRound: timerService.currentRound,
            currentPhase: timerService.currentPhase == .work ? "work" : "rest",
            timeRemaining: timerService.timeRemaining,
            totalElapsed: timerService.totalElapsed,
            pausedSeconds: timerService.pausedSeconds,
            startTime: session.startedAt,
            templateName: template.name,
            workSeconds: template.workSeconds,
            restSeconds: template.restSeconds,
            totalRounds: template.rounds
        )

        // Schedule notifications
        Task {
            do {
                try await scheduleTimerNotifications(
                    template: template,
                    startTime: Date()
                )
            } catch {
                DebugLogger.shared.warning("BackgroundTimerManager", "Notification scheduling failed: \(error.localizedDescription)")
            }
        }

        // Schedule background refresh
        scheduleBackgroundRefresh()
    }

    /// Handle app returning to foreground
    /// - Parameter timerService: The timer service to restore
    func handleAppWillEnterForeground(timerService: IntervalTimerService) async {
        guard let savedState = restoreTimerState() else {
            return
        }

        DebugLogger.shared.info("DEBUG", 
            "App entering foreground - restoring timer",
        )

        // Calculate elapsed time while backgrounded
        let backgroundElapsed = Date().timeIntervalSince(savedState.startTime)

        DebugLogger.shared.info("DEBUG", 
            "Background elapsed: \(Int(backgroundElapsed))s",
        )

        // Timer service will handle recalculating current round/phase
        // based on elapsed time

        // Clear notifications and saved state
        clearTimerState()
    }
}

