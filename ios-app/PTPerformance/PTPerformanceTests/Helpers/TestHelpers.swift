//
//  TestHelpers.swift
//  PTPerformanceTests
//
//  Common test utilities, factories, and extensions for writing unit tests.
//  Import this file to access reusable test infrastructure.
//

import XCTest
@testable import PTPerformance

// MARK: - Test UUIDs

/// Stable UUIDs for testing that can be referenced across tests
enum TestUUIDs {
    /// A stable UUID for patient-related tests
    static let patient = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// A stable UUID for exercise template tests
    static let exerciseTemplate = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// A stable UUID for workout template tests
    static let workoutTemplate = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    /// A stable UUID for deload recommendation tests
    static let deloadRecommendation = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    /// A stable UUID for fatigue accumulation tests
    static let fatigueAccumulation = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!

    /// A stable UUID for general purpose tests
    static let generic = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

    /// Generate a sequence of stable UUIDs for array-based tests
    static func sequence(count: Int, startingAt: Int = 100) -> [UUID] {
        (0..<count).map { index in
            let number = startingAt + index
            let hexString = String(format: "%012d", number)
            return UUID(uuidString: "00000000-0000-0000-0000-\(hexString)")!
        }
    }
}

// MARK: - Test Dates

/// Common date utilities for testing
enum TestDates {
    /// A reference date for consistent test data: January 15, 2024 at 12:00 PM UTC
    static let reference: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }()

    /// Create a date relative to the reference date
    static func daysFromReference(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: reference)!
    }

    /// Create a date relative to now
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }

    /// Create a date string in ISO8601 format
    static func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// Create a date string in yyyy-MM-dd format (database format)
    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Mock Data Builders

/// Factory methods for creating test data
enum TestDataFactory {

    // MARK: - Fatigue Data

    /// Create a mock FatigueSummary with customizable properties
    static func fatigueSummary(
        fatigueScore: Double = 50.0,
        fatigueBand: String = "moderate",
        avgReadiness7d: Double = 65.0,
        acuteChronicRatio: Double = 1.2,
        consecutiveLowDays: Int = 2,
        contributingFactors: [String] = ["Test factor 1", "Test factor 2"]
    ) -> FatigueSummary {
        FatigueSummary(
            fatigueScore: fatigueScore,
            fatigueBand: fatigueBand,
            avgReadiness7d: avgReadiness7d,
            acuteChronicRatio: acuteChronicRatio,
            consecutiveLowDays: consecutiveLowDays,
            contributingFactors: contributingFactors
        )
    }

    /// Create a mock FatigueAccumulation with customizable properties
    static func fatigueAccumulation(
        id: UUID = TestUUIDs.fatigueAccumulation,
        patientId: UUID = TestUUIDs.patient,
        calculationDate: Date = TestDates.reference,
        avgReadiness7d: Double? = 65.0,
        avgReadiness14d: Double? = 68.0,
        trainingLoad7d: Double? = 1200.0,
        trainingLoad14d: Double? = 2400.0,
        acuteChronicRatio: Double? = 1.1,
        consecutiveLowReadiness: Int = 2,
        missedRepsCount7d: Int = 0,
        highRpeCount7d: Int = 1,
        painReports7d: Int = 0,
        fatigueScore: Double = 55.0,
        fatigueBand: FatigueBand = .moderate,
        deloadRecommended: Bool = false,
        deloadUrgency: DeloadUrgency = .suggested,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) -> FatigueAccumulation {
        FatigueAccumulation(
            id: id,
            patientId: patientId,
            calculationDate: calculationDate,
            avgReadiness7d: avgReadiness7d,
            avgReadiness14d: avgReadiness14d,
            trainingLoad7d: trainingLoad7d,
            trainingLoad14d: trainingLoad14d,
            acuteChronicRatio: acuteChronicRatio,
            consecutiveLowReadiness: consecutiveLowReadiness,
            missedRepsCount7d: missedRepsCount7d,
            highRpeCount7d: highRpeCount7d,
            painReports7d: painReports7d,
            fatigueScore: fatigueScore,
            fatigueBand: fatigueBand,
            deloadRecommended: deloadRecommended,
            deloadUrgency: deloadUrgency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create a sequence of fatigue accumulations for trend testing
    static func fatigueTrend(
        days: Int = 7,
        patientId: UUID = TestUUIDs.patient,
        startingScore: Double = 45.0,
        scoreIncrement: Double = 5.0
    ) -> [FatigueAccumulation] {
        (0..<days).map { daysAgo in
            let date = TestDates.daysFromNow(-days + 1 + daysAgo)
            let score = startingScore + Double(daysAgo) * scoreIncrement
            let band: FatigueBand = score > 70 ? .high : (score > 50 ? .moderate : .low)
            return fatigueAccumulation(
                id: TestUUIDs.sequence(count: days)[daysAgo],
                patientId: patientId,
                calculationDate: date,
                fatigueScore: score,
                fatigueBand: band
            )
        }
    }

    // MARK: - Deload Data

    /// Create a mock DeloadPrescription with customizable properties
    static func deloadPrescription(
        durationDays: Int = 7,
        loadReductionPct: Double = 0.30,
        volumeReductionPct: Double = 0.40,
        focus: String = "Active recovery and mobility work",
        suggestedStartDate: Date = Date()
    ) -> DeloadPrescription {
        DeloadPrescription(
            durationDays: durationDays,
            loadReductionPct: loadReductionPct,
            volumeReductionPct: volumeReductionPct,
            focus: focus,
            suggestedStartDate: suggestedStartDate
        )
    }

    /// Create a mock DeloadRecommendation with customizable properties
    static func deloadRecommendation(
        id: UUID = TestUUIDs.deloadRecommendation,
        patientId: UUID = TestUUIDs.patient,
        deloadRecommended: Bool = true,
        urgency: DeloadUrgency = .recommended,
        reasoning: String = "High fatigue accumulation detected over the past week.",
        fatigueSummary: FatigueSummary? = nil,
        deloadPrescription: DeloadPrescription? = nil,
        createdAt: Date = Date(),
        status: DeloadRecommendationStatus? = nil,
        activatedAt: Date? = nil,
        dismissedAt: Date? = nil,
        dismissalReason: String? = nil
    ) -> DeloadRecommendation {
        DeloadRecommendation(
            id: id,
            patientId: patientId,
            deloadRecommended: deloadRecommended,
            urgency: urgency,
            reasoning: reasoning,
            fatigueSummary: fatigueSummary ?? Self.fatigueSummary(fatigueScore: 72.0, fatigueBand: "high"),
            deloadPrescription: deloadPrescription ?? Self.deloadPrescription(),
            createdAt: createdAt,
            status: status,
            activatedAt: activatedAt,
            dismissedAt: dismissedAt,
            dismissalReason: dismissalReason
        )
    }

    // MARK: - Workout Recommendation Data

    /// Create a mock WorkoutRecommendationItem with customizable properties
    static func workoutRecommendationItem(
        templateId: String = UUID().uuidString,
        templateName: String = "Mock Workout",
        matchScore: Int = 85,
        reasoning: String = "Mock reasoning for test",
        category: String? = "strength",
        durationMinutes: Int? = 45,
        difficulty: String? = "intermediate"
    ) -> WorkoutRecommendationItem {
        WorkoutRecommendationItem(
            templateId: templateId,
            templateName: templateName,
            matchScore: matchScore,
            reasoning: reasoning,
            category: category,
            durationMinutes: durationMinutes,
            difficulty: difficulty
        )
    }

    /// Create a mock WorkoutRecommendationContextSummary
    static func workoutRecommendationContext(
        readinessBand: String? = "green",
        readinessScore: Double? = 85.0,
        recentWorkoutCount: Int = 3,
        activeGoals: [String] = ["Build strength", "Improve endurance"]
    ) -> WorkoutRecommendationContextSummary {
        WorkoutRecommendationContextSummary(
            readinessBand: readinessBand,
            readinessScore: readinessScore,
            recentWorkoutCount: recentWorkoutCount,
            activeGoals: activeGoals
        )
    }

    // MARK: - Exercise Substitution Data

    /// Create a mock ExerciseSubstitutionItem
    static func exerciseSubstitutionItem(
        originalExerciseId: String = TestUUIDs.exerciseTemplate.uuidString,
        originalExerciseName: String = "Barbell Squat",
        substituteExerciseId: String = UUID().uuidString,
        substituteExerciseName: String = "Bodyweight Squat",
        reason: String = "Selected for no equipment requirement"
    ) -> ExerciseSubstitutionItem {
        ExerciseSubstitutionItem(
            originalExerciseId: originalExerciseId,
            originalExerciseName: originalExerciseName,
            substituteExerciseId: substituteExerciseId,
            substituteExerciseName: substituteExerciseName,
            reason: reason,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            techniqueCues: nil,
            formCues: nil,
            commonMistakes: nil,
            safetyNotes: nil,
            equipmentRequired: nil,
            musclesTargeted: nil,
            difficultyLevel: nil
        )
    }

    /// Create a mock ExerciseSubstitution from an item
    static func exerciseSubstitution(
        originalExerciseId: String = TestUUIDs.exerciseTemplate.uuidString,
        originalExerciseName: String = "Barbell Squat",
        substituteExerciseName: String = "Bodyweight Squat",
        confidence: Int = 85
    ) -> ExerciseSubstitution {
        let item = exerciseSubstitutionItem(
            originalExerciseId: originalExerciseId,
            originalExerciseName: originalExerciseName,
            substituteExerciseName: substituteExerciseName
        )
        return ExerciseSubstitution(from: item, confidence: confidence)
    }
}

// MARK: - JSON Test Helpers

/// Utilities for JSON encoding/decoding tests
enum JSONTestHelpers {

    /// Create a JSONDecoder with the app's standard configuration
    static var standardDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// Create a JSONEncoder with the app's standard configuration
    static var standardEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    /// Encode an object to JSON and decode it back, useful for round-trip tests
    static func roundTrip<T: Codable>(_ object: T, file: StaticString = #filePath, line: UInt = #line) throws -> T {
        let data = try standardEncoder.encode(object)
        return try standardDecoder.decode(T.self, from: data)
    }

    /// Create Data from a JSON string for decoding tests
    static func jsonData(_ jsonString: String) -> Data {
        jsonString.data(using: .utf8)!
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {

    // MARK: - Async Testing Utilities

    /// Wait for a condition to become true with a timeout
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        description: String = "Condition",
        condition: @escaping () -> Bool
    ) {
        let expectation = XCTestExpectation(description: description)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                timer.invalidate()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }

    // MARK: - Collection Assertions

    /// Assert that a collection contains exactly the expected elements in any order
    func assertContainsAll<T: Equatable>(
        _ collection: [T],
        expected: [T],
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(collection.count, expected.count, "Collection count mismatch. \(message)", file: file, line: line)
        for element in expected {
            XCTAssertTrue(collection.contains(element), "Collection missing element: \(element). \(message)", file: file, line: line)
        }
    }

    /// Assert that a collection is sorted according to a comparator
    func assertSorted<T>(
        _ collection: [T],
        by areInIncreasingOrder: (T, T) -> Bool,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for i in 0..<(collection.count - 1) {
            let isOrdered = areInIncreasingOrder(collection[i], collection[i + 1]) ||
                            !areInIncreasingOrder(collection[i + 1], collection[i])
            XCTAssertTrue(isOrdered, "Collection not sorted at index \(i). \(message)", file: file, line: line)
        }
    }

    // MARK: - Double Assertions

    /// Assert that two doubles are equal within a default accuracy
    func assertApproximatelyEqual(
        _ value1: Double,
        _ value2: Double,
        accuracy: Double = 0.01,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(value1, value2, accuracy: accuracy, message, file: file, line: line)
    }

    /// Assert that a double is within a range
    func assertInRange(
        _ value: Double,
        min: Double,
        max: Double,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(value, min, "Value \(value) below minimum \(min). \(message)", file: file, line: line)
        XCTAssertLessThanOrEqual(value, max, "Value \(value) above maximum \(max). \(message)", file: file, line: line)
    }

    // MARK: - Error Assertions

    /// Assert that an async expression throws a specific error type
    func assertThrowsAsync<T, E: Error & Equatable>(
        _ expression: @autoclosure () async throws -> T,
        expectedError: E,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error \(expectedError) but no error was thrown. \(message)", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, "Unexpected error: \(error). \(message)", file: file, line: line)
        } catch {
            XCTFail("Unexpected error type: \(error). Expected \(E.self). \(message)", file: file, line: line)
        }
    }
}

// MARK: - Test Constants

/// Common test constants
enum TestConstants {
    /// Standard accuracy for floating-point comparisons
    static let floatAccuracy: Double = 0.01

    /// Standard timeout for async operations
    static let asyncTimeout: TimeInterval = 5.0

    /// Short timeout for quick async operations
    static let shortTimeout: TimeInterval = 1.0

    /// Long timeout for slower operations
    static let longTimeout: TimeInterval = 10.0
}

// MARK: - Exercise Test Helpers

extension TestDataFactory {

    // MARK: - Exercise Data

    /// Create a mock Exercise with customizable properties
    static func exercise(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        exerciseTemplateId: UUID = UUID(),
        sequence: Int? = 1,
        targetSets: Int? = 3,
        targetReps: Int? = 10,
        prescribedSets: Int? = nil,
        prescribedReps: String? = "10",
        prescribedLoad: Double? = nil,
        loadUnit: String? = "lbs",
        restPeriodSeconds: Int? = 90,
        notes: String? = nil,
        templateName: String = "Test Exercise",
        category: String? = "test",
        bodyRegion: String? = "upper"
    ) -> Exercise {
        let template = Exercise.ExerciseTemplate(
            id: exerciseTemplateId,
            name: templateName,
            category: category,
            body_region: bodyRegion,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            videoDuration: nil,
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )

        return Exercise(
            id: id,
            session_id: sessionId,
            exercise_template_id: exerciseTemplateId,
            sequence: sequence,
            target_sets: targetSets,
            target_reps: targetReps,
            prescribed_sets: prescribedSets,
            prescribed_reps: prescribedReps,
            prescribed_load: prescribedLoad,
            load_unit: loadUnit,
            rest_period_seconds: restPeriodSeconds,
            notes: notes,
            exercise_templates: template
        )
    }

    /// Create a mock Exercise using only target_sets (new schema)
    static func exerciseWithTargetSets(
        sets: Int = 3,
        reps: Int = 10,
        load: Double? = nil,
        name: String = "Test Exercise"
    ) -> Exercise {
        return exercise(
            targetSets: sets,
            targetReps: reps,
            prescribedSets: nil,
            prescribedReps: nil,
            prescribedLoad: load,
            templateName: name
        )
    }

    /// Create a mock Exercise using only prescribed_sets (legacy schema)
    static func exerciseWithPrescribedSets(
        sets: Int = 3,
        reps: String = "10",
        load: Double? = nil,
        name: String = "Test Exercise"
    ) -> Exercise {
        return exercise(
            targetSets: nil,
            targetReps: nil,
            prescribedSets: sets,
            prescribedReps: reps,
            prescribedLoad: load,
            templateName: name
        )
    }

    /// Create a mock Session with customizable properties
    static func session(
        id: UUID = UUID(),
        phaseId: UUID = UUID(),
        name: String = "Test Session",
        sequence: Int = 1,
        weekday: Int? = nil,
        notes: String? = nil,
        completed: Bool? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        totalVolume: Double? = nil,
        avgRpe: Double? = nil,
        avgPain: Double? = nil,
        durationMinutes: Int? = nil
    ) -> Session {
        return Session(
            id: id,
            phase_id: phaseId,
            name: name,
            sequence: sequence,
            weekday: weekday,
            notes: notes,
            created_at: Date(),
            completed: completed,
            started_at: startedAt,
            completed_at: completedAt,
            total_volume: totalVolume,
            avg_rpe: avgRpe,
            avg_pain: avgPain,
            duration_minutes: durationMinutes
        )
    }

    /// Create a completed session with metrics
    static func completedSession(
        name: String = "Completed Session",
        totalVolume: Double = 10000.0,
        avgRpe: Double = 7.0,
        avgPain: Double = 2.0,
        durationMinutes: Int = 45
    ) -> Session {
        return session(
            name: name,
            completed: true,
            startedAt: Date().addingTimeInterval(-Double(durationMinutes * 60)),
            completedAt: Date(),
            totalVolume: totalVolume,
            avgRpe: avgRpe,
            avgPain: avgPain,
            durationMinutes: durationMinutes
        )
    }

    /// Create multiple mock exercises with sequential order
    static func exercises(count: Int, baseLoad: Double = 100.0) -> [Exercise] {
        return (0..<count).map { index in
            exercise(
                sequence: index + 1,
                targetSets: 3,
                targetReps: 10,
                prescribedLoad: baseLoad + Double(index * 10),
                templateName: "Exercise \(index + 1)"
            )
        }
    }
}
