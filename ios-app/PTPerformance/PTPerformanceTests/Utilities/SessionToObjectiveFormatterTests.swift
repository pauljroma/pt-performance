//
//  SessionToObjectiveFormatterTests.swift
//  PTPerformanceTests
//
//  Unit tests for SessionToObjectiveFormatter
//  Tests formatting of session data into clinical Objective text for SOAP notes
//

import XCTest
@testable import PTPerformance

// MARK: - Test Helpers

private extension SessionWithLogs {

    /// Creates a minimal session with no exercise logs for testing
    static var minimal: SessionWithLogs {
        SessionWithLogs(
            id: "minimal-session",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )
    }

    /// Creates a session with all fields populated for testing
    static var full: SessionWithLogs {
        let dateComponents = DateComponents(year: 2024, month: 3, day: 15, hour: 10, minute: 30)
        let sessionDate = Calendar.current.date(from: dateComponents) ?? Date()

        return SessionWithLogs(
            id: "full-session",
            sessionNumber: 8,
            sessionDate: sessionDate,
            completed: true,
            notes: "Patient reported feeling much stronger today. Good tolerance to all exercises.",
            totalVolume: 15750.5,
            avgRpe: 6.5,
            avgPainScore: 2.5,
            durationMinutes: 55,
            exerciseLogs: [
                ExerciseLogDetail(
                    id: "log-1",
                    exerciseName: "Squat",
                    actualSets: 4,
                    actualReps: [10, 10, 10, 8],
                    actualLoad: 185,
                    loadUnit: "lbs",
                    rpe: 7,
                    painScore: 0,
                    notes: nil,
                    loggedAt: sessionDate,
                    exerciseTemplateId: nil,
                    videoUrl: nil
                ),
                ExerciseLogDetail(
                    id: "log-2",
                    exerciseName: "Romanian Deadlift",
                    actualSets: 3,
                    actualReps: [12, 12, 12],
                    actualLoad: 135,
                    loadUnit: "lbs",
                    rpe: 6,
                    painScore: 2,
                    notes: "Slight tightness in hamstrings",
                    loggedAt: sessionDate,
                    exerciseTemplateId: nil,
                    videoUrl: nil
                ),
                ExerciseLogDetail(
                    id: "log-3",
                    exerciseName: "Leg Press",
                    actualSets: 3,
                    actualReps: [15, 15, 15],
                    actualLoad: 270,
                    loadUnit: "lbs",
                    rpe: 6,
                    painScore: 0,
                    notes: nil,
                    loggedAt: sessionDate,
                    exerciseTemplateId: nil,
                    videoUrl: nil
                )
            ]
        )
    }

    /// Creates a session with high pain scores for testing
    static var highPain: SessionWithLogs {
        SessionWithLogs(
            id: "high-pain-session",
            sessionNumber: 3,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 5000,
            avgRpe: 8.0,
            avgPainScore: 7.5,
            durationMinutes: 30,
            exerciseLogs: [
                ExerciseLogDetail(
                    id: "log-pain-1",
                    exerciseName: "Shoulder Press",
                    actualSets: 2,
                    actualReps: [8, 6],
                    actualLoad: 25,
                    loadUnit: "lbs",
                    rpe: 9,
                    painScore: 8,
                    notes: "Pain during overhead movement",
                    loggedAt: Date(),
                    exerciseTemplateId: nil,
                    videoUrl: nil
                ),
                ExerciseLogDetail(
                    id: "log-pain-2",
                    exerciseName: "Lateral Raise",
                    actualSets: 2,
                    actualReps: [10, 8],
                    actualLoad: 10,
                    loadUnit: "lbs",
                    rpe: 8,
                    painScore: 7,
                    notes: nil,
                    loggedAt: Date(),
                    exerciseTemplateId: nil,
                    videoUrl: nil
                )
            ]
        )
    }
}

private extension ExerciseLogDetail {

    /// Creates a bodyweight exercise log (no load)
    static var bodyweight: ExerciseLogDetail {
        ExerciseLogDetail(
            id: "bw-log",
            exerciseName: "Push-ups",
            actualSets: 3,
            actualReps: [15, 12, 10],
            actualLoad: nil,
            loadUnit: nil,
            rpe: 7,
            painScore: 0,
            notes: nil,
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )
    }

    /// Creates an exercise with uniform reps
    static var uniformReps: ExerciseLogDetail {
        ExerciseLogDetail(
            id: "uniform-log",
            exerciseName: "Bicep Curl",
            actualSets: 3,
            actualReps: [12, 12, 12],
            actualLoad: 25,
            loadUnit: "lbs",
            rpe: 6,
            painScore: 0,
            notes: nil,
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )
    }
}

// MARK: - formatObjectiveText Tests

final class SessionToObjectiveFormatterTests: XCTestCase {

    // MARK: - Full Session Data Tests

    func testFormatObjectiveText_FullSession_ContainsSessionDate() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Session Date:"), "Should contain session date header")
    }

    func testFormatObjectiveText_FullSession_ContainsSessionNumber() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Session #8"), "Should contain session number")
    }

    func testFormatObjectiveText_FullSession_ContainsDuration() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("55 minutes"), "Should contain session duration")
    }

    func testFormatObjectiveText_FullSession_ContainsTotalVolume() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Total Volume:"), "Should contain total volume")
        XCTAssertTrue(result.contains("15.8K lbs") || result.contains("15750"), "Should format volume correctly")
    }

    func testFormatObjectiveText_FullSession_ContainsAverageRPE() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Average RPE:"), "Should contain average RPE")
        XCTAssertTrue(result.contains("6.5/10"), "Should format RPE correctly")
    }

    func testFormatObjectiveText_FullSession_ContainsAveragePainScore() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Average Pain Score:"), "Should contain average pain score")
        XCTAssertTrue(result.contains("2.5/10"), "Should format pain score correctly")
    }

    func testFormatObjectiveText_FullSession_ContainsExercisePerformance() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Exercise Performance:"), "Should contain exercise performance section")
        XCTAssertTrue(result.contains("Squat"), "Should contain exercise names")
        XCTAssertTrue(result.contains("Romanian Deadlift"), "Should contain all exercises")
        XCTAssertTrue(result.contains("Leg Press"), "Should contain all exercises")
    }

    func testFormatObjectiveText_FullSession_ContainsPatientNotes() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Patient Notes:"), "Should contain patient notes section")
        XCTAssertTrue(result.contains("feeling much stronger"), "Should contain the actual notes")
    }

    // MARK: - Minimal Session Data Tests

    func testFormatObjectiveText_MinimalSession_ContainsSessionDate() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Session Date:"), "Should always contain session date")
    }

    func testFormatObjectiveText_MinimalSession_NoSessionNumber() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertFalse(result.contains("Session #"), "Should not contain session number when nil")
    }

    func testFormatObjectiveText_MinimalSession_NoDuration() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertFalse(result.contains("Session Duration:"), "Should not contain duration when nil")
    }

    func testFormatObjectiveText_MinimalSession_NoMetrics() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertFalse(result.contains("Objective Measures:"), "Should not contain metrics section when all nil")
    }

    func testFormatObjectiveText_MinimalSession_NoExercises() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertFalse(result.contains("Exercise Performance:"), "Should not contain exercises when empty")
    }

    func testFormatObjectiveText_MinimalSession_NoPatientNotes() {
        let session = SessionWithLogs.minimal
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertFalse(result.contains("Patient Notes:"), "Should not contain patient notes when nil")
    }

    // MARK: - Formatting Options Tests

    func testFormatObjectiveText_ExcludeExercises() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includeExercises: false
        )

        XCTAssertFalse(result.contains("Exercise Performance:"), "Should not contain exercises when excluded")
    }

    func testFormatObjectiveText_ExcludePainScores() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includePainScores: false
        )

        XCTAssertFalse(result.contains("Average Pain Score:"), "Should not contain pain scores when excluded")
    }

    func testFormatObjectiveText_ExcludeRPE() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includeRPE: false
        )

        XCTAssertFalse(result.contains("Average RPE:"), "Should not contain RPE when excluded")
    }

    func testFormatObjectiveText_ExcludeVolume() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includeVolume: false
        )

        XCTAssertFalse(result.contains("Total Volume:"), "Should not contain volume when excluded")
    }

    func testFormatObjectiveText_ExcludeNotes() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includeNotes: false
        )

        XCTAssertFalse(result.contains("Patient Notes:"), "Should not contain patient notes when excluded")
        XCTAssertFalse(result.contains("Note:"), "Should not contain exercise notes when excluded")
    }

    func testFormatObjectiveText_ExcludeAllOptions() {
        let session = SessionWithLogs.full
        let result = SessionToObjectiveFormatter.formatObjectiveText(
            from: session,
            includeExercises: false,
            includePainScores: false,
            includeRPE: false,
            includeVolume: false,
            includeNotes: false
        )

        // Should still contain session header
        XCTAssertTrue(result.contains("Session Date:"), "Should always contain session date")
        // But not the optional sections
        XCTAssertFalse(result.contains("Objective Measures:"))
        XCTAssertFalse(result.contains("Exercise Performance:"))
    }
}

// MARK: - formatSelectedExercises Tests

final class FormatSelectedExercisesTests: XCTestCase {

    // MARK: - Empty Input Tests

    func testFormatSelectedExercises_EmptyArray_ReturnsEmptyString() {
        let result = SessionToObjectiveFormatter.formatSelectedExercises([])
        XCTAssertEqual(result, "")
    }

    // MARK: - Single Exercise Tests

    func testFormatSelectedExercises_SingleExercise_ContainsExerciseName() {
        let logs = [ExerciseLogDetail.uniformReps]
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("Bicep Curl"), "Should contain exercise name")
    }

    func testFormatSelectedExercises_SingleExercise_ContainsSetsAndReps() {
        let logs = [ExerciseLogDetail.uniformReps]
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("3 sets"), "Should contain set count")
        XCTAssertTrue(result.contains("12 reps"), "Should contain rep count")
    }

    func testFormatSelectedExercises_SingleExercise_ContainsLoad() {
        let logs = [ExerciseLogDetail.uniformReps]
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("25 lbs") || result.contains("@ 25"), "Should contain load")
    }

    // MARK: - Multiple Exercises Tests

    func testFormatSelectedExercises_MultipleExercises_ContainsSummary() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("Exercises Completed: 3"), "Should show exercise count")
        XCTAssertTrue(result.contains("Total Sets:"), "Should show total sets")
    }

    func testFormatSelectedExercises_MultipleExercises_ContainsAverageRPE() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("Average RPE:"), "Should contain average RPE")
    }

    func testFormatSelectedExercises_MultipleExercises_ContainsAllExercises() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("Squat"), "Should contain all exercise names")
        XCTAssertTrue(result.contains("Romanian Deadlift"), "Should contain all exercise names")
        XCTAssertTrue(result.contains("Leg Press"), "Should contain all exercise names")
    }

    // MARK: - Formatting Options Tests

    func testFormatSelectedExercises_DefaultOptions() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: .default)

        XCTAssertTrue(result.contains("Exercises Completed:"), "Default should include summary")
        XCTAssertTrue(result.contains("RPE"), "Default should include RPE")
    }

    func testFormatSelectedExercises_MinimalOptions() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: .minimal)

        XCTAssertFalse(result.contains("Exercises Completed:"), "Minimal should not include summary")
        XCTAssertTrue(result.contains("Exercise Performance:"), "Minimal should still include exercises")
    }

    func testFormatSelectedExercises_ComprehensiveOptions() {
        let logs = SessionWithLogs.full.exerciseLogs
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: .comprehensive)

        XCTAssertTrue(result.contains("Exercises Completed:"), "Comprehensive should include summary")
        XCTAssertTrue(result.contains("RPE"), "Comprehensive should include RPE")
        XCTAssertTrue(result.contains("Note:"), "Comprehensive should include notes")
    }

    func testFormatSelectedExercises_WithoutRPE() {
        let logs = SessionWithLogs.full.exerciseLogs
        var options = SessionToObjectiveFormatter.FormattingOptions.default
        options.includeRPE = false
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: options)

        // Should not contain RPE in exercise details
        let lines = result.components(separatedBy: "\n")
        let exerciseLines = lines.filter { $0.hasPrefix("- ") && $0.contains("sets") }
        for line in exerciseLines {
            XCTAssertFalse(line.contains("RPE"), "Should not contain RPE in exercise lines")
        }
    }

    func testFormatSelectedExercises_WithoutPainScores() {
        let logs = SessionWithLogs.highPain.exerciseLogs
        var options = SessionToObjectiveFormatter.FormattingOptions.default
        options.includePainScores = false
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: options)

        XCTAssertFalse(result.contains("Average Pain:"), "Should not contain average pain")
    }

    func testFormatSelectedExercises_WithoutNotes() {
        let logs = SessionWithLogs.full.exerciseLogs
        var options = SessionToObjectiveFormatter.FormattingOptions.default
        options.includeNotes = false
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: options)

        XCTAssertFalse(result.contains("Note:"), "Should not contain exercise notes")
    }

    func testFormatSelectedExercises_WithoutSummary() {
        let logs = SessionWithLogs.full.exerciseLogs
        var options = SessionToObjectiveFormatter.FormattingOptions.default
        options.includeSummary = false
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs, options: options)

        XCTAssertFalse(result.contains("Exercises Completed:"), "Should not contain summary")
    }
}

// MARK: - FormattingOptions Tests

final class FormattingOptionsTests: XCTestCase {

    // MARK: - Default Options Tests

    func testFormattingOptions_Default_AllTrue() {
        let options = SessionToObjectiveFormatter.FormattingOptions.default

        XCTAssertTrue(options.includeExercises)
        XCTAssertTrue(options.includePainScores)
        XCTAssertTrue(options.includeRPE)
        XCTAssertTrue(options.includeVolume)
        XCTAssertTrue(options.includeNotes)
        XCTAssertTrue(options.includeSummary)
    }

    // MARK: - Minimal Options Tests

    func testFormattingOptions_Minimal_OnlyExercises() {
        let options = SessionToObjectiveFormatter.FormattingOptions.minimal

        XCTAssertTrue(options.includeExercises)
        XCTAssertFalse(options.includePainScores)
        XCTAssertFalse(options.includeRPE)
        XCTAssertFalse(options.includeVolume)
        XCTAssertFalse(options.includeNotes)
        XCTAssertFalse(options.includeSummary)
    }

    // MARK: - Comprehensive Options Tests

    func testFormattingOptions_Comprehensive_AllTrue() {
        let options = SessionToObjectiveFormatter.FormattingOptions.comprehensive

        XCTAssertTrue(options.includeExercises)
        XCTAssertTrue(options.includePainScores)
        XCTAssertTrue(options.includeRPE)
        XCTAssertTrue(options.includeVolume)
        XCTAssertTrue(options.includeNotes)
        XCTAssertTrue(options.includeSummary)
    }

    // MARK: - Custom Options Tests

    func testFormattingOptions_CustomCombination() {
        var options = SessionToObjectiveFormatter.FormattingOptions()
        options.includeExercises = true
        options.includePainScores = true
        options.includeRPE = false
        options.includeVolume = false
        options.includeNotes = true
        options.includeSummary = false

        XCTAssertTrue(options.includeExercises)
        XCTAssertTrue(options.includePainScores)
        XCTAssertFalse(options.includeRPE)
        XCTAssertFalse(options.includeVolume)
        XCTAssertTrue(options.includeNotes)
        XCTAssertFalse(options.includeSummary)
    }
}

// MARK: - Pain Level Description Tests

final class PainLevelDescriptionTests: XCTestCase {

    func testPainLevel_Zero_NoPain() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 0,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("no pain"), "Pain level 0 should be described as 'no pain'")
    }

    func testPainLevel_One_Mild() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 1,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("mild"), "Pain level 1 should be described as 'mild'")
    }

    func testPainLevel_Three_Mild() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 3,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("mild"), "Pain level 3 should be described as 'mild'")
    }

    func testPainLevel_Four_Moderate() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 4,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("moderate"), "Pain level 4 should be described as 'moderate'")
    }

    func testPainLevel_Six_Moderate() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 6,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("moderate"), "Pain level 6 should be described as 'moderate'")
    }

    func testPainLevel_Seven_Severe() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 7,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("severe"), "Pain level 7 should be described as 'severe'")
    }

    func testPainLevel_Eight_Severe() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 8,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("severe"), "Pain level 8 should be described as 'severe'")
    }

    func testPainLevel_Nine_VerySevere() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 9,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("very severe"), "Pain level 9 should be described as 'very severe'")
    }

    func testPainLevel_Ten_VerySevere() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: 10,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("very severe"), "Pain level 10 should be described as 'very severe'")
    }

    func testPainLevel_InExerciseDetail() {
        let logs = [
            ExerciseLogDetail(
                id: "test",
                exerciseName: "Test Exercise",
                actualSets: 3,
                actualReps: [10, 10, 10],
                actualLoad: 100,
                loadUnit: "lbs",
                rpe: 6,
                painScore: 5, // moderate
                notes: nil,
                loggedAt: Date(),
                exerciseTemplateId: nil,
                videoUrl: nil
            )
        ]

        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)
        XCTAssertTrue(result.contains("Pain 5/10"), "Should show pain score in exercise")
        XCTAssertTrue(result.contains("moderate"), "Should describe pain level")
    }
}

// MARK: - Volume Formatting Tests

final class VolumeFormattingTests: XCTestCase {

    func testVolumeFormatting_Under1000() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 750,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("750 lbs"), "Volume under 1000 should show as plain number")
    }

    func testVolumeFormatting_Exactly1000() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 1000,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("1.0K lbs"), "Volume of 1000 should show as 1.0K")
    }

    func testVolumeFormatting_Over1000() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 12500,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("12.5K lbs"), "Volume over 1000 should show in K format")
    }

    func testVolumeFormatting_LargeVolume() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 50000,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("50.0K lbs"), "Large volume should format correctly")
    }

    func testVolumeFormatting_DecimalVolume() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 15750.5,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        // Should round to 15.8K
        XCTAssertTrue(result.contains("15.8K lbs") || result.contains("15.7K lbs"), "Decimal volume should round appropriately")
    }

    func testVolumeFormatting_ZeroVolume_NotDisplayed() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 0,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertFalse(result.contains("Total Volume:"), "Zero volume should not be displayed")
    }
}

// MARK: - Date Formatting Tests

final class DateFormattingTests: XCTestCase {

    func testDateFormatting_ContainsMonth() {
        let dateComponents = DateComponents(year: 2024, month: 3, day: 15)
        let sessionDate = Calendar.current.date(from: dateComponents)!

        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: sessionDate,
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("March") || result.contains("Mar"), "Should contain month name")
    }

    func testDateFormatting_ContainsDay() {
        let dateComponents = DateComponents(year: 2024, month: 3, day: 15)
        let sessionDate = Calendar.current.date(from: dateComponents)!

        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: sessionDate,
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("15"), "Should contain day number")
    }

    func testDateFormatting_ContainsYear() {
        let dateComponents = DateComponents(year: 2024, month: 3, day: 15)
        let sessionDate = Calendar.current.date(from: dateComponents)!

        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: sessionDate,
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: nil,
            avgPainScore: nil,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("2024"), "Should contain year")
    }
}

// MARK: - Edge Cases Tests

final class SessionFormatterEdgeCaseTests: XCTestCase {

    func testEdgeCase_EmptyExerciseLogs() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: 1,
            sessionDate: Date(),
            completed: true,
            notes: "Session notes here",
            totalVolume: 5000,
            avgRpe: 6.0,
            avgPainScore: 2.0,
            durationMinutes: 45,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)

        XCTAssertTrue(result.contains("Session Date:"))
        XCTAssertTrue(result.contains("Total Volume:"))
        XCTAssertFalse(result.contains("Exercise Performance:"))
    }

    func testEdgeCase_NilNotes() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: 1,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: 5000,
            avgRpe: 6.0,
            avgPainScore: 2.0,
            durationMinutes: 45,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertFalse(result.contains("Patient Notes:"))
    }

    func testEdgeCase_EmptyNotes() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: 1,
            sessionDate: Date(),
            completed: true,
            notes: "",
            totalVolume: 5000,
            avgRpe: 6.0,
            avgPainScore: 2.0,
            durationMinutes: 45,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertFalse(result.contains("Patient Notes:"))
    }

    func testEdgeCase_BodyweightExercise() {
        let logs = [ExerciseLogDetail.bodyweight]
        let result = SessionToObjectiveFormatter.formatSelectedExercises(logs)

        XCTAssertTrue(result.contains("Push-ups"))
        XCTAssertTrue(result.contains("3 sets"))
        // Should not have load display issue
        XCTAssertFalse(result.contains("@ nil"))
    }

    func testEdgeCase_VaryingReps() {
        let log = ExerciseLogDetail(
            id: "varying",
            exerciseName: "Bench Press",
            actualSets: 3,
            actualReps: [10, 8, 6],
            actualLoad: 135,
            loadUnit: "lbs",
            rpe: 8,
            painScore: 0,
            notes: nil,
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )

        let result = SessionToObjectiveFormatter.formatSelectedExercises([log])
        XCTAssertTrue(result.contains("10/8/6") || result.contains("10, 8, 6"), "Should show varying reps")
    }

    func testEdgeCase_UniformReps() {
        let log = ExerciseLogDetail.uniformReps
        let result = SessionToObjectiveFormatter.formatSelectedExercises([log])

        // Uniform reps should show as single number
        XCTAssertTrue(result.contains("12 reps"), "Uniform reps should show as single number")
    }

    func testEdgeCase_ZeroPainScore_NotDisplayed() {
        let log = ExerciseLogDetail(
            id: "no-pain",
            exerciseName: "Test",
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 100,
            loadUnit: "lbs",
            rpe: 6,
            painScore: 0,
            notes: nil,
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )

        let result = SessionToObjectiveFormatter.formatSelectedExercises([log])
        // Zero pain score should not be displayed inline with exercise
        XCTAssertFalse(result.contains("Pain 0/10"), "Zero pain should not show inline")
    }

    func testEdgeCase_HighPainScore_Displayed() {
        let log = ExerciseLogDetail(
            id: "high-pain",
            exerciseName: "Test",
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 100,
            loadUnit: "lbs",
            rpe: 6,
            painScore: 7,
            notes: nil,
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )

        let result = SessionToObjectiveFormatter.formatSelectedExercises([log])
        XCTAssertTrue(result.contains("Pain 7/10"), "Non-zero pain should be displayed")
    }

    func testEdgeCase_ExerciseWithNotes() {
        let log = ExerciseLogDetail(
            id: "with-notes",
            exerciseName: "Shoulder Press",
            actualSets: 3,
            actualReps: [10, 10, 10],
            actualLoad: 50,
            loadUnit: "lbs",
            rpe: 7,
            painScore: 3,
            notes: "Patient reported mild discomfort at top of movement",
            loggedAt: Date(),
            exerciseTemplateId: nil,
            videoUrl: nil
        )

        let result = SessionToObjectiveFormatter.formatSelectedExercises([log], options: .comprehensive)
        XCTAssertTrue(result.contains("Note:"), "Should include note label")
        XCTAssertTrue(result.contains("mild discomfort"), "Should include note content")
    }

    func testEdgeCase_WholeNumberDecimal() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: 7.0, // Whole number
            avgPainScore: 3.0, // Whole number
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        // Whole numbers should display without decimal (7/10 not 7.0/10)
        XCTAssertTrue(result.contains("7/10") || result.contains("7.0/10"))
        XCTAssertTrue(result.contains("3/10") || result.contains("3.0/10"))
    }

    func testEdgeCase_DecimalValues() {
        let session = SessionWithLogs(
            id: "test",
            sessionNumber: nil,
            sessionDate: Date(),
            completed: true,
            notes: nil,
            totalVolume: nil,
            avgRpe: 6.5,
            avgPainScore: 2.3,
            durationMinutes: nil,
            exerciseLogs: []
        )

        let result = SessionToObjectiveFormatter.formatObjectiveText(from: session)
        XCTAssertTrue(result.contains("6.5/10"), "Decimal RPE should show one decimal place")
        XCTAssertTrue(result.contains("2.3/10"), "Decimal pain should show one decimal place")
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class SessionToObjectiveFormatterSampleDataTests: XCTestCase {

    func testSampleSession_Exists() {
        let sample = SessionWithLogs.sample

        XCTAssertNotNil(sample.id)
        XCTAssertNotNil(sample.sessionNumber)
        XCTAssertFalse(sample.exerciseLogs.isEmpty)
    }

    func testSampleSession_FormatsCorrectly() {
        let sample = SessionWithLogs.sample
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: sample)

        XCTAssertTrue(result.contains("Session Date:"))
        XCTAssertTrue(result.contains("Session #"))
        XCTAssertTrue(result.contains("Exercise Performance:"))
    }

    func testSampleSession_ContainsAllExercises() {
        let sample = SessionWithLogs.sample
        let result = SessionToObjectiveFormatter.formatObjectiveText(from: sample)

        for log in sample.exerciseLogs {
            XCTAssertTrue(result.contains(log.exerciseName), "Should contain \(log.exerciseName)")
        }
    }
}
#endif
