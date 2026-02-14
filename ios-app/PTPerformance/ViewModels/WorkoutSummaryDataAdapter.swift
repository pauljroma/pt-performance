//
//  WorkoutSummaryDataAdapter.swift
//  PTPerformance
//
//  ACP-1016: Workout Summary Enhancement
//  Adapter to convert workout data to enhanced summary format
//

import Foundation

// MARK: - Workout Summary Data Adapter

/// Converts workout session data to enhanced summary format
@MainActor
struct WorkoutSummaryDataAdapter {

    // MARK: - Convert from OptimisticWorkoutViewModel

    static func createSummaryData(
        from viewModel: OptimisticWorkoutViewModel,
        sessionName: String = "Workout",
        currentStreak: Int = 0,
        previousSessionVolume: Double? = nil
    ) -> WorkoutSummaryData {
        let exercises = viewModel.exercises
        let exerciseStates = viewModel.workoutState.exerciseStates

        // Create exercise summaries
        let exerciseSummaries = exercises.compactMap { exercise -> ExerciseSummary? in
            guard let state = exerciseStates[exercise.id], state.isCompleted else {
                return nil
            }

            let totalReps = state.repsPerSet.reduce(0, +)
            let avgWeight = state.weightPerSet.isEmpty ? 0 : state.weightPerSet.reduce(0, +) / Double(state.weightPerSet.count)
            let volume = Double(totalReps) * avgWeight

            // Determine muscle group from exercise category
            let muscleGroup = exercise.movement_pattern ?? "general"

            // For now, we don't detect PRs without historical data
            // This would need to be enhanced with actual PR detection logic
            return ExerciseSummary(
                id: exercise.id,
                name: exercise.exercise_name ?? "Exercise",
                sets: state.completedSets,
                reps: state.repsPerSet,
                weight: avgWeight > 0 ? avgWeight : nil,
                volume: volume,
                isPersonalRecord: false,
                prDetails: nil,
                muscleGroup: muscleGroup
            )
        }

        // Calculate muscle group breakdown
        let muscleGroups = calculateMuscleGroupBreakdown(from: exerciseSummaries)

        return WorkoutSummaryData(
            workoutName: sessionName,
            completedAt: Date(),
            duration: viewModel.workoutDuration,
            totalVolume: viewModel.totalVolume,
            previousVolume: previousSessionVolume,
            exercisesCompleted: exerciseSummaries,
            muscleGroupBreakdown: muscleGroups,
            currentStreak: currentStreak
        )
    }

    // MARK: - Convert from ManualSession

    static func createSummaryData(
        from session: ManualSession,
        currentStreak: Int = 0,
        previousSessionVolume: Double? = nil
    ) -> WorkoutSummaryData {
        // Create exercise summaries from manual session exercises
        let exerciseSummaries = session.exercises.map { exercise -> ExerciseSummary in
            let reps = parseReps(exercise.targetReps, sets: exercise.targetSets)
            let volume = calculateVolume(reps: reps, weight: exercise.targetLoad ?? 0)

            return ExerciseSummary(
                id: exercise.id,
                name: exercise.exerciseName,
                sets: exercise.targetSets ?? 0,
                reps: reps,
                weight: exercise.targetLoad,
                volume: volume,
                isPersonalRecord: false,
                prDetails: nil,
                muscleGroup: exercise.blockType
            )
        }

        // Calculate muscle group breakdown
        let muscleGroups = calculateMuscleGroupBreakdown(from: exerciseSummaries)

        return WorkoutSummaryData(
            workoutName: session.name ?? "Workout",
            completedAt: session.completedAt ?? Date(),
            duration: session.durationMinutes,
            totalVolume: session.totalVolume ?? 0,
            previousVolume: previousSessionVolume,
            exercisesCompleted: exerciseSummaries,
            muscleGroupBreakdown: muscleGroups,
            currentStreak: currentStreak
        )
    }

    // MARK: - Helper Methods

    private static func calculateMuscleGroupBreakdown(from exercises: [ExerciseSummary]) -> [MuscleGroupVolume] {
        var groupVolumes: [String: Double] = [:]

        for exercise in exercises {
            let group = normalizeMuscleGroup(exercise.muscleGroup ?? "other")
            groupVolumes[group, default: 0] += exercise.volume
        }

        return groupVolumes.map { MuscleGroupVolume(muscleGroup: $0.key, volume: $0.value) }
            .filter { $0.volume > 0 }
            .sorted { $0.volume > $1.volume }
    }

    private static func normalizeMuscleGroup(_ group: String) -> String {
        let normalized = group.lowercased().trimmingCharacters(in: .whitespaces)

        // Map common variations to standard groups
        switch normalized {
        case "push", "chest", "pecs", "bench":
            return "push"
        case "pull", "back", "lats", "rows":
            return "pull"
        case "legs", "squat", "lower", "quads", "hamstrings":
            return "legs"
        case "shoulders", "delts", "press":
            return "shoulders"
        case "arms", "biceps", "triceps":
            return "arms"
        case "core", "abs", "abdominals":
            return "core"
        default:
            return normalized
        }
    }

    private static func parseReps(_ repsString: String?, sets: Int?) -> [Int] {
        guard let repsString = repsString else { return [] }

        // Try to parse as comma-separated list
        let components = repsString.split(separator: ",")
        if components.count > 1 {
            return components.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }

        // Try to parse as single number
        if let reps = Int(repsString.trimmingCharacters(in: .whitespaces)) {
            let setsCount = sets ?? 3
            return Array(repeating: reps, count: setsCount)
        }

        // Try to parse as range (e.g., "8-10")
        if repsString.contains("-") {
            let parts = repsString.split(separator: "-")
            if parts.count == 2, let lower = Int(parts[0].trimmingCharacters(in: .whitespaces)) {
                let setsCount = sets ?? 3
                return Array(repeating: lower, count: setsCount)
            }
        }

        return []
    }

    private static func calculateVolume(reps: [Int], weight: Double) -> Double {
        let totalReps = reps.reduce(0, +)
        return Double(totalReps) * weight
    }
}

// MARK: - Workout Summary Data Model

struct WorkoutSummaryData {
    let workoutName: String
    let completedAt: Date
    let duration: Int?
    let totalVolume: Double
    let previousVolume: Double?
    let exercisesCompleted: [ExerciseSummary]
    let muscleGroupBreakdown: [MuscleGroupVolume]
    let currentStreak: Int
}

// MARK: - OptimisticWorkoutViewModel Extension

extension OptimisticWorkoutViewModel {
    var workoutDuration: Int? {
        guard let startTime = startTime else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        return Int(elapsed / 60) // Convert to minutes
    }

    func generateSummaryData(
        sessionName: String = "Workout",
        currentStreak: Int = 0,
        previousVolume: Double? = nil
    ) -> WorkoutSummaryData {
        return WorkoutSummaryDataAdapter.createSummaryData(
            from: self,
            sessionName: sessionName,
            currentStreak: currentStreak,
            previousSessionVolume: previousVolume
        )
    }
}
