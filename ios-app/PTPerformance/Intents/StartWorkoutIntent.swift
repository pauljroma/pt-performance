import AppIntents
import Foundation

/// Siri Intent to start today's scheduled workout
/// Phrase: "Hey Siri, start my workout in Modus"
@available(iOS 16.0, *)
struct StartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Start today's scheduled workout in Modus")

    /// Optional workout name to start a specific workout
    @Parameter(title: "Workout Name")
    var workoutName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$workoutName) workout") {
            \.$workoutName
        }
    }

    /// Opens the app and navigates to today's workout
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & OpensIntent {
        // Log the Siri intent action
        print("[StartWorkoutIntent] Starting workout via Siri")

        // Check if user has an active session flag
        // Note: We use UserDefaults here because SecureStore is not available in App Intents context
        // The hasActiveSession flag is set by the main app when authentication succeeds
        let hasSession = UserDefaults.standard.bool(forKey: "hasActiveSession")

        guard hasSession else {
            return .result(dialog: "Please open Modus and sign in first to start your workout.")
        }

        // Check if there's a scheduled workout for today
        // The actual workout loading happens in the app when it opens
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let dayName = calendar.weekdaySymbols[dayOfWeek - 1]

        if let workoutName = workoutName {
            return .result(dialog: "Starting your \(workoutName) workout. Let's go!")
        } else {
            return .result(dialog: "Opening your \(dayName) workout. Let's crush it!")
        }
    }
}

// MARK: - App Entity for Workout Selection

@available(iOS 16.0, *)
struct WorkoutEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Workout"
    static var defaultQuery = WorkoutQuery()

    var id: String
    var name: String
    var dayOfWeek: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 16.0, *)
struct WorkoutQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WorkoutEntity] {
        // Return workouts matching the identifiers
        // In a full implementation, this would query from the database
        return identifiers.compactMap { id in
            WorkoutEntity(id: id, name: id, dayOfWeek: nil)
        }
    }

    func suggestedEntities() async throws -> [WorkoutEntity] {
        // Return commonly used workouts
        // In a full implementation, this would fetch from the user's program
        return [
            WorkoutEntity(id: "today", name: "Today's Workout", dayOfWeek: nil),
            WorkoutEntity(id: "upper", name: "Upper Body", dayOfWeek: nil),
            WorkoutEntity(id: "lower", name: "Lower Body", dayOfWeek: nil),
            WorkoutEntity(id: "full", name: "Full Body", dayOfWeek: nil)
        ]
    }
}
