import Foundation
import HealthKit

// MARK: - Workout Export Service

/// Focused service for exporting workouts to Apple Health (ACP-827)
/// Handles workout creation, calorie estimation, and duplicate detection
@MainActor
class WorkoutExportService {

    // MARK: - Properties

    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// Initialize with a HealthKit store
    /// - Parameter healthStore: The HKHealthStore to use for queries and saving
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Methods

    /// Export a completed workout session to Apple Health
    /// - Parameter session: The completed session with timing and metrics
    /// - Returns: The HKWorkout that was saved to HealthKit
    /// - Throws: HealthKitError if save fails
    @discardableResult
    func exportWorkout(session: Session) async throws -> HKWorkout {
        // Validate session has required timing data
        guard let startTime = session.started_at,
              let endTime = session.completed_at else {
            throw HealthKitError.invalidDate
        }

        // Calculate estimated calories if not provided
        let estimatedCalories = calculateEstimatedCalories(
            durationMinutes: session.duration_minutes ?? Int(endTime.timeIntervalSince(startTime) / 60),
            totalVolume: session.total_volume
        )

        // Build metadata for the workout
        let metadata: [String: Any] = [
            "PTPerformanceSessionId": session.id.uuidString,
            HKMetadataKeyIndoorWorkout: true
        ]

        return try await createAndSaveWorkout(
            startTime: startTime,
            endTime: endTime,
            estimatedCalories: estimatedCalories,
            metadata: metadata
        )
    }

    /// Export a completed manual workout session to Apple Health
    /// - Parameter session: The completed manual session
    /// - Returns: The HKWorkout that was saved to HealthKit
    /// - Throws: HealthKitError if save fails
    @discardableResult
    func exportManualWorkout(session: ManualSession) async throws -> HKWorkout {
        // Validate session has required timing data
        guard let startTime = session.startedAt,
              let endTime = session.completedAt else {
            throw HealthKitError.invalidDate
        }

        // Calculate estimated calories
        let estimatedCalories = calculateEstimatedCalories(
            durationMinutes: session.durationMinutes ?? Int(endTime.timeIntervalSince(startTime) / 60),
            totalVolume: session.totalVolume
        )

        // Build metadata for the workout
        var metadata: [String: Any] = [
            "PTPerformanceSessionId": session.id.uuidString,
            HKMetadataKeyIndoorWorkout: true
        ]

        if let name = session.name {
            metadata["WorkoutName"] = name
        }

        return try await createAndSaveWorkout(
            startTime: startTime,
            endTime: endTime,
            estimatedCalories: estimatedCalories,
            metadata: metadata
        )
    }

    /// Check if a workout was already exported to HealthKit
    /// Prevents duplicate exports by checking metadata
    /// - Parameter sessionId: The PTPerformance session ID
    /// - Returns: True if workout with this session ID exists in HealthKit
    func isWorkoutExported(sessionId: UUID) async throws -> Bool {
        // Query for workouts with matching session ID in metadata
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: "PTPerformanceSessionId",
            allowedValues: [sessionId.uuidString]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }

                let exists = (samples?.count ?? 0) > 0
                continuation.resume(returning: exists)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch recent workouts exported from PTPerformance
    /// - Parameter limit: Maximum number of workouts to fetch
    /// - Returns: Array of exported workouts with metadata
    func fetchExportedWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForObjects(withMetadataKey: "PTPerformanceSessionId")
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private Methods

    /// Create and save a workout to HealthKit using HKWorkoutBuilder
    private func createAndSaveWorkout(
        startTime: Date,
        endTime: Date,
        estimatedCalories: Double,
        metadata: [String: Any]
    ) async throws -> HKWorkout {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: nil
        )

        do {
            try await builder.beginCollection(at: startTime)

            // Add metadata to the builder before finishing
            try await builder.addMetadata(metadata)

            // Add energy burned sample
            guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                throw HealthKitError.saveFailed("Failed to create energy type")
            }
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories),
                start: startTime,
                end: endTime
            )
            try await builder.addSamples([energySample])

            try await builder.endCollection(at: endTime)

            let workout = try await builder.finishWorkout()
            guard let savedWorkout = workout else {
                throw HealthKitError.saveFailed("Failed to create workout")
            }

            return savedWorkout
        } catch let error as HealthKitError {
            throw error
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Estimate calories burned based on workout duration and volume
    /// Uses a simplified MET-based calculation for strength training
    /// - Parameters:
    ///   - durationMinutes: Duration of workout in minutes
    ///   - totalVolume: Total weight lifted in pounds (optional)
    /// - Returns: Estimated calories burned
    private func calculateEstimatedCalories(durationMinutes: Int?, totalVolume: Double?) -> Double {
        let duration = Double(durationMinutes ?? 30)

        // Base calculation: ~5-6 calories per minute for strength training
        // This is a conservative estimate (MET ~3.5-4.0 for weight training)
        var baseCalories = duration * 5.5

        // Add bonus for high volume workouts (indicates more intense training)
        if let volume = totalVolume, volume > 0 {
            // Add ~1 calorie per 100 lbs lifted as a rough intensity adjustment
            let volumeBonus = volume / 100.0
            baseCalories += volumeBonus
        }

        return baseCalories
    }
}
