import AppIntents
import Foundation

/// Siri Intent to start today's scheduled workout
/// Phrase: "Hey Siri, start my workout in PT Performance"
@available(iOS 16.0, *)
struct StartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Start today's scheduled workout in PT Performance")

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

        // Check if user is authenticated by looking for stored session
        // TODO: SECURITY - The hasActiveSession flag itself is not sensitive (just a boolean),
        // but consider using SecureStore to check for auth token presence instead.
        // This would be more reliable than a separate flag that could get out of sync.
        // Example: let hasSession = (try? SecureStore.shared.getString(forKey: .authToken)) != nil
        let hasSession = UserDefaults.standard.bool(forKey: "hasActiveSession")

        guard hasSession else {
            return .result(
                dialog: "Please open PT Performance and sign in first to start your workout."
            ) {
                // Open app for login
            }
        }

        // Check if there's a scheduled workout for today
        // The actual workout loading happens in the app when it opens
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let dayName = calendar.weekdaySymbols[dayOfWeek - 1]

        if let workoutName = workoutName {
            return .result(
                dialog: "Starting your \(workoutName) workout. Let's go!"
            ) {
                // Deep link will be handled by the app
            }
        } else {
            return .result(
                dialog: "Opening your \(dayName) workout. Let's crush it!"
            ) {
                // Deep link will be handled by the app
            }
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
