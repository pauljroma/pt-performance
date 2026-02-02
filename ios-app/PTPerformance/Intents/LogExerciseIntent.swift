import AppIntents
import Foundation

/// Siri Intent to log exercise sets and reps
/// Phrase: "Hey Siri, log 3 sets of 10 in PT Performance"
@available(iOS 16.0, *)
struct LogExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Exercise"
    static var description = IntentDescription("Log sets and reps for an exercise")

    @Parameter(title: "Exercise Name")
    var exerciseName: String?

    @Parameter(title: "Sets", default: 3)
    var sets: Int

    @Parameter(title: "Reps", default: 10)
    var reps: Int

    @Parameter(title: "Weight (lbs)")
    var weight: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$sets) sets of \(\.$reps) reps") {
            \.$exerciseName
            \.$weight
        }
    }

    /// Opens the app to show the logged exercise
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Log the Siri intent action
        print("[LogExerciseIntent] Logging exercise via Siri: \(sets) sets of \(reps)")

        // Validate inputs
        guard sets > 0, sets <= 20 else {
            return .result(dialog: "Please specify between 1 and 20 sets.")
        }

        guard reps > 0, reps <= 100 else {
            return .result(dialog: "Please specify between 1 and 100 reps.")
        }

        // Build the confirmation message
        var message = "Logged \(sets) sets of \(reps) reps"

        if let exerciseName = exerciseName, !exerciseName.isEmpty {
            message = "Logged \(sets) sets of \(reps) reps for \(exerciseName)"
        }

        if let weight = weight, weight > 0 {
            message += " at \(Int(weight)) pounds"
        }

        message += "."

        // Store the intent data for the app to process when it opens
        let intentData: [String: Any] = [
            "type": "logExercise",
            "sets": sets,
            "reps": reps,
            "exerciseName": exerciseName ?? "",
            "weight": weight ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: intentData) {
            UserDefaults.standard.set(encoded, forKey: "pendingSiriIntent")
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Quick Log Intent (Simplified)

/// Simplified intent for quick logging without exercise name
/// Phrase: "Hey Siri, log my set in PT Performance"
@available(iOS 16.0, *)
struct QuickLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Log Set"
    static var description = IntentDescription("Quickly log a set for the current exercise")

    @Parameter(title: "Reps Completed")
    var reps: Int

    @Parameter(title: "Weight Used (lbs)")
    var weight: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$reps) reps") {
            \.$weight
        }
    }

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("[QuickLogIntent] Quick logging \(reps) reps via Siri")

        guard reps > 0, reps <= 100 else {
            return .result(dialog: "Please specify between 1 and 100 reps.")
        }

        var message = "Logged \(reps) reps"
        if let weight = weight, weight > 0 {
            message += " at \(Int(weight)) lbs"
        }

        // Store for app to process
        let intentData: [String: Any] = [
            "type": "quickLog",
            "reps": reps,
            "weight": weight ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: intentData) {
            UserDefaults.standard.set(encoded, forKey: "pendingSiriIntent")
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Exercise Entity

@available(iOS 16.0, *)
struct ExerciseEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Exercise"
    static var defaultQuery = ExerciseQuery()

    var id: String
    var name: String
    var category: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 16.0, *)
struct ExerciseQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ExerciseEntity] {
        return identifiers.map { id in
            ExerciseEntity(id: id, name: id, category: nil)
        }
    }

    func suggestedEntities() async throws -> [ExerciseEntity] {
        // Return common exercises
        return [
            ExerciseEntity(id: "squat", name: "Squat", category: "Lower Body"),
            ExerciseEntity(id: "bench-press", name: "Bench Press", category: "Upper Body"),
            ExerciseEntity(id: "deadlift", name: "Deadlift", category: "Lower Body"),
            ExerciseEntity(id: "overhead-press", name: "Overhead Press", category: "Upper Body"),
            ExerciseEntity(id: "row", name: "Barbell Row", category: "Upper Body"),
            ExerciseEntity(id: "pullup", name: "Pull-up", category: "Upper Body"),
            ExerciseEntity(id: "lunge", name: "Lunge", category: "Lower Body"),
            ExerciseEntity(id: "plank", name: "Plank", category: "Core")
        ]
    }
}
