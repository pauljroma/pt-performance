import AppIntents
import Foundation

/// App Shortcuts Provider for Modus
/// Defines all Siri shortcuts available for the app
@available(iOS 16.0, *)
struct PTPerformanceShortcuts: AppShortcutsProvider {

    /// All available app shortcuts
    static var appShortcuts: [AppShortcut] {
        // Start Workout Shortcut
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start my workout in \(.applicationName)",
                "Begin training in \(.applicationName)",
                "Start workout in \(.applicationName)",
                "Begin my workout in \(.applicationName)",
                "Let's train in \(.applicationName)",
                "Start today's workout in \(.applicationName)"
            ],
            shortTitle: "Start Workout",
            systemImageName: "figure.strengthtraining.traditional"
        )

        // Log Exercise Shortcut
        AppShortcut(
            intent: LogExerciseIntent(),
            phrases: [
                "Log exercise in \(.applicationName)",
                "Record my sets in \(.applicationName)",
                "Log my workout in \(.applicationName)",
                "Add exercise to \(.applicationName)"
            ],
            shortTitle: "Log Exercise",
            systemImageName: "checklist"
        )

        // Quick Log Shortcut
        AppShortcut(
            intent: QuickLogIntent(),
            phrases: [
                "Quick log in \(.applicationName)",
                "Log my set in \(.applicationName)",
                "Record reps in \(.applicationName)"
            ],
            shortTitle: "Quick Log",
            systemImageName: "plus.circle.fill"
        )

        // Check Readiness Shortcut
        AppShortcut(
            intent: CheckReadinessIntent(),
            phrases: [
                "Check my readiness in \(.applicationName)",
                "What's my readiness in \(.applicationName)",
                "How ready am I in \(.applicationName)",
                "Check readiness score in \(.applicationName)",
                "Am I ready to train in \(.applicationName)"
            ],
            shortTitle: "Check Readiness",
            systemImageName: "gauge.with.dots.needle.33percent"
        )

        // Log Readiness Shortcut
        AppShortcut(
            intent: LogReadinessIntent(),
            phrases: [
                "Log my readiness in \(.applicationName)",
                "Do readiness check-in in \(.applicationName)",
                "Daily check-in in \(.applicationName)",
                "Record how I feel in \(.applicationName)"
            ],
            shortTitle: "Log Readiness",
            systemImageName: "heart.text.square"
        )

        // View Progress Shortcut
        AppShortcut(
            intent: ViewProgressIntent(),
            phrases: [
                "Show my progress in \(.applicationName)",
                "View workout stats in \(.applicationName)",
                "Check my streak in \(.applicationName)",
                "How am I doing in \(.applicationName)"
            ],
            shortTitle: "View Progress",
            systemImageName: "chart.line.uptrend.xyaxis"
        )

        // Rest Timer Shortcut
        AppShortcut(
            intent: StartRestTimerIntent(),
            phrases: [
                "Start rest timer in \(.applicationName)",
                "Rest timer in \(.applicationName)",
                "Time my rest in \(.applicationName)"
            ],
            shortTitle: "Rest Timer",
            systemImageName: "timer"
        )
    }
}

// MARK: - View Progress Intent

/// Intent to view workout progress and stats
@available(iOS 16.0, *)
struct ViewProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "View Progress"
    static var description = IntentDescription("View your workout progress and statistics")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DebugLogger.shared.log("[ViewProgressIntent] Viewing progress via Siri", level: .diagnostic)

        // Get cached stats from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.getmodus.app") ?? UserDefaults.standard

        let workoutStreak = defaults.integer(forKey: "currentWorkoutStreak")
        let totalWorkouts = defaults.integer(forKey: "totalWorkoutsCompleted")

        if workoutStreak > 0 || totalWorkouts > 0 {
            var message = ""

            if workoutStreak > 0 {
                message += "You're on a \(workoutStreak) day streak! "
            }

            if totalWorkouts > 0 {
                message += "You've completed \(totalWorkouts) workouts total."
            }

            return .result(dialog: IntentDialog(stringLiteral: message.isEmpty ? "Opening your progress..." : message))
        }

        return .result(dialog: "Opening your workout progress...")
    }
}

// MARK: - Rest Timer Intent

/// Intent to start a rest timer between sets
@available(iOS 16.0, *)
struct StartRestTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Rest Timer"
    static var description = IntentDescription("Start a rest timer between sets")

    @Parameter(title: "Duration (seconds)", default: 90)
    var seconds: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$seconds) second rest timer")
    }

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DebugLogger.shared.log("[StartRestTimerIntent] Starting \(seconds) second rest timer via Siri", level: .diagnostic)

        // Validate duration
        guard seconds > 0, seconds <= 600 else {
            return .result(dialog: "Please specify a rest duration between 1 and 600 seconds.")
        }

        // Store for app to process
        let intentData: [String: Any] = [
            "type": "restTimer",
            "seconds": seconds,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: intentData) {
            UserDefaults.standard.set(encoded, forKey: "pendingSiriIntent")
        }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if minutes > 0 {
            if remainingSeconds > 0 {
                return .result(dialog: IntentDialog(stringLiteral: "Starting \(minutes) minute \(remainingSeconds) second rest timer. Take a breather!"))
            } else {
                return .result(dialog: IntentDialog(stringLiteral: "Starting \(minutes) minute rest timer. Take a breather!"))
            }
        } else {
            return .result(dialog: IntentDialog(stringLiteral: "Starting \(seconds) second rest timer. Quick rest!"))
        }
    }
}
