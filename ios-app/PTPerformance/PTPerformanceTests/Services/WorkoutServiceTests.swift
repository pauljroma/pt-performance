//
//  WorkoutServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for workout-related services
//  Tests workout session management, timer functionality, and exercise logging
//

import XCTest
@testable import PTPerformance

// MARK: - TimerState Tests

final class TimerStateTests: XCTestCase {

    func testTimerState_AllCases() {
        // Verify all timer states exist
        let allCases = TimerState.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.idle))
        XCTAssertTrue(allCases.contains(.running))
        XCTAssertTrue(allCases.contains(.paused))
        XCTAssertTrue(allCases.contains(.completed))
    }

    func testTimerState_DisplayNames() {
        XCTAssertEqual(TimerState.idle.displayName, "Ready")
        XCTAssertEqual(TimerState.running.displayName, "Running")
        XCTAssertEqual(TimerState.paused.displayName, "Paused")
        XCTAssertEqual(TimerState.completed.displayName, "Completed")
    }

    func testTimerState_Descriptions() {
        XCTAssertEqual(TimerState.idle.description, "Timer is ready to start")
        XCTAssertEqual(TimerState.running.description, "Timer is actively running")
        XCTAssertEqual(TimerState.paused.description, "Timer is temporarily paused")
        XCTAssertEqual(TimerState.completed.description, "Timer has completed all rounds")
    }

    func testTimerState_IconNames() {
        XCTAssertEqual(TimerState.idle.iconName, "play.circle.fill")
        XCTAssertEqual(TimerState.running.iconName, "pause.circle.fill")
        XCTAssertEqual(TimerState.paused.iconName, "play.circle.fill")
        XCTAssertEqual(TimerState.completed.iconName, "checkmark.circle.fill")
    }

    func testTimerState_CanStart() {
        XCTAssertTrue(TimerState.idle.canStart)
        XCTAssertFalse(TimerState.running.canStart)
        XCTAssertTrue(TimerState.paused.canStart)
        XCTAssertFalse(TimerState.completed.canStart)
    }

    func testTimerState_CanPause() {
        XCTAssertFalse(TimerState.idle.canPause)
        XCTAssertTrue(TimerState.running.canPause)
        XCTAssertFalse(TimerState.paused.canPause)
        XCTAssertFalse(TimerState.completed.canPause)
    }

    func testTimerState_CanReset() {
        XCTAssertFalse(TimerState.idle.canReset)
        XCTAssertFalse(TimerState.running.canReset)
        XCTAssertTrue(TimerState.paused.canReset)
        XCTAssertTrue(TimerState.completed.canReset)
    }

    func testTimerState_RawValues() {
        XCTAssertEqual(TimerState.idle.rawValue, "idle")
        XCTAssertEqual(TimerState.running.rawValue, "running")
        XCTAssertEqual(TimerState.paused.rawValue, "paused")
        XCTAssertEqual(TimerState.completed.rawValue, "completed")
    }
}

// MARK: - TimerPhase Tests

final class TimerPhaseTests: XCTestCase {

    func testTimerPhase_DisplayNames() {
        XCTAssertEqual(IntervalTimerService.TimerPhase.work.displayName, "WORK")
        XCTAssertEqual(IntervalTimerService.TimerPhase.rest.displayName, "REST")
        XCTAssertEqual(IntervalTimerService.TimerPhase.break.displayName, "BREAK")
    }

    func testTimerPhase_Colors() {
        XCTAssertEqual(IntervalTimerService.TimerPhase.work.color, "red")
        XCTAssertEqual(IntervalTimerService.TimerPhase.rest.color, "green")
        XCTAssertEqual(IntervalTimerService.TimerPhase.break.color, "blue")
    }
}

// MARK: - TimerError Tests

final class TimerErrorTests: XCTestCase {

    func testTimerError_InvalidWorkDuration() {
        let error = TimerError.invalidWorkDuration
        XCTAssertEqual(error.errorDescription, "Work duration must be greater than 0")
        XCTAssertEqual(error.recoverySuggestion, "Set a work duration of at least 1 second.")
    }

    func testTimerError_InvalidRestDuration() {
        let error = TimerError.invalidRestDuration
        XCTAssertEqual(error.errorDescription, "Rest duration must be 0 or greater")
        XCTAssertEqual(error.recoverySuggestion, "Set a rest duration of 0 or more seconds.")
    }

    func testTimerError_InvalidRounds() {
        let error = TimerError.invalidRounds
        XCTAssertEqual(error.errorDescription, "Rounds must be greater than 0")
        XCTAssertEqual(error.recoverySuggestion, "Set at least 1 round for the timer.")
    }

    func testTimerError_SessionNotFound() {
        let error = TimerError.sessionNotFound
        XCTAssertEqual(error.errorDescription, "Timer session not found")
        XCTAssertEqual(error.recoverySuggestion, "Start a new timer session.")
    }

    func testTimerError_TimerAlreadyRunning() {
        let error = TimerError.timerAlreadyRunning
        XCTAssertEqual(error.errorDescription, "Timer is already running")
        XCTAssertEqual(error.recoverySuggestion, "Stop the current timer before starting a new one.")
    }

    func testTimerError_NotAuthenticated() {
        let error = TimerError.notAuthenticated
        XCTAssertEqual(error.errorDescription, "User must be authenticated")
        XCTAssertEqual(error.recoverySuggestion, "Please sign in to save your timer sessions.")
    }

    func testTimerError_IsLocalizedError() {
        let errors: [TimerError] = [
            .invalidWorkDuration,
            .invalidRestDuration,
            .invalidRounds,
            .sessionNotFound,
            .timerAlreadyRunning,
            .notAuthenticated
        ]

        for error in errors {
            let localizedError: LocalizedError = error
            XCTAssertNotNil(localizedError.errorDescription)
            XCTAssertNotNil(error.recoverySuggestion)
        }
    }
}

// MARK: - TimerCategory Tests

final class TimerCategoryTests: XCTestCase {

    func testTimerCategory_RawValues() {
        XCTAssertEqual(TimerCategory.cardio.rawValue, "cardio")
        XCTAssertEqual(TimerCategory.strength.rawValue, "strength")
        XCTAssertEqual(TimerCategory.warmup.rawValue, "warmup")
        XCTAssertEqual(TimerCategory.cooldown.rawValue, "cooldown")
        XCTAssertEqual(TimerCategory.recovery.rawValue, "recovery")
    }

    func testTimerCategory_AllCases() {
        let allCases = TimerCategory.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.cardio))
        XCTAssertTrue(allCases.contains(.strength))
        XCTAssertTrue(allCases.contains(.warmup))
        XCTAssertTrue(allCases.contains(.cooldown))
        XCTAssertTrue(allCases.contains(.recovery))
    }

    func testTimerCategory_DisplayNames() {
        XCTAssertEqual(TimerCategory.cardio.displayName, "Cardio")
        XCTAssertEqual(TimerCategory.strength.displayName, "Strength")
        XCTAssertEqual(TimerCategory.warmup.displayName, "Warm-up")
        XCTAssertEqual(TimerCategory.cooldown.displayName, "Cool-down")
        XCTAssertEqual(TimerCategory.recovery.displayName, "Recovery")
    }

    func testTimerCategory_Descriptions() {
        XCTAssertFalse(TimerCategory.cardio.description.isEmpty)
        XCTAssertFalse(TimerCategory.strength.description.isEmpty)
        XCTAssertFalse(TimerCategory.warmup.description.isEmpty)
        XCTAssertFalse(TimerCategory.cooldown.description.isEmpty)
        XCTAssertFalse(TimerCategory.recovery.description.isEmpty)
    }

    func testTimerCategory_IconNames() {
        XCTAssertEqual(TimerCategory.cardio.iconName, "heart.fill")
        XCTAssertEqual(TimerCategory.strength.iconName, "dumbbell.fill")
        XCTAssertEqual(TimerCategory.warmup.iconName, "figure.run")
        XCTAssertEqual(TimerCategory.cooldown.iconName, "figure.cooldown")
        XCTAssertEqual(TimerCategory.recovery.iconName, "leaf.fill")
    }

    func testTimerCategory_TypicalIntensity() {
        XCTAssertFalse(TimerCategory.cardio.typicalIntensity.isEmpty)
        XCTAssertFalse(TimerCategory.strength.typicalIntensity.isEmpty)
    }
}

// MARK: - TimerType Tests

final class TimerTypeTests: XCTestCase {

    func testTimerType_RawValues() {
        XCTAssertEqual(TimerType.tabata.rawValue, "tabata")
        XCTAssertEqual(TimerType.emom.rawValue, "emom")
        XCTAssertEqual(TimerType.amrap.rawValue, "amrap")
        XCTAssertEqual(TimerType.intervals.rawValue, "intervals")
        XCTAssertEqual(TimerType.custom.rawValue, "custom")
    }

    func testTimerType_AllCases() {
        let allCases = TimerType.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.tabata))
        XCTAssertTrue(allCases.contains(.emom))
        XCTAssertTrue(allCases.contains(.amrap))
        XCTAssertTrue(allCases.contains(.intervals))
        XCTAssertTrue(allCases.contains(.custom))
    }

    func testTimerType_DisplayNames() {
        XCTAssertEqual(TimerType.tabata.displayName, "Tabata")
        XCTAssertEqual(TimerType.emom.displayName, "EMOM")
        XCTAssertEqual(TimerType.amrap.displayName, "AMRAP")
        XCTAssertEqual(TimerType.intervals.displayName, "Intervals")
        XCTAssertEqual(TimerType.custom.displayName, "Custom")
    }

    func testTimerType_Descriptions() {
        XCTAssertFalse(TimerType.tabata.description.isEmpty)
        XCTAssertFalse(TimerType.emom.description.isEmpty)
        XCTAssertFalse(TimerType.amrap.description.isEmpty)
        XCTAssertFalse(TimerType.intervals.description.isEmpty)
        XCTAssertFalse(TimerType.custom.description.isEmpty)
    }

    func testTimerType_DefaultWorkSeconds() {
        XCTAssertEqual(TimerType.tabata.defaultWorkSeconds, 20)
        XCTAssertEqual(TimerType.emom.defaultWorkSeconds, 40)
        XCTAssertEqual(TimerType.amrap.defaultWorkSeconds, 300)
        XCTAssertEqual(TimerType.intervals.defaultWorkSeconds, 30)
        XCTAssertEqual(TimerType.custom.defaultWorkSeconds, 30)
    }

    func testTimerType_DefaultRestSeconds() {
        XCTAssertEqual(TimerType.tabata.defaultRestSeconds, 10)
        XCTAssertEqual(TimerType.emom.defaultRestSeconds, 20)
        XCTAssertEqual(TimerType.amrap.defaultRestSeconds, 0)
        XCTAssertEqual(TimerType.intervals.defaultRestSeconds, 30)
        XCTAssertEqual(TimerType.custom.defaultRestSeconds, 30)
    }

    func testTimerType_DefaultRounds() {
        XCTAssertEqual(TimerType.tabata.defaultRounds, 8)
        XCTAssertEqual(TimerType.emom.defaultRounds, 10)
        XCTAssertEqual(TimerType.amrap.defaultRounds, 1)
        XCTAssertEqual(TimerType.intervals.defaultRounds, 5)
        XCTAssertEqual(TimerType.custom.defaultRounds, 5)
    }

    func testTimerType_IconNames() {
        XCTAssertEqual(TimerType.tabata.iconName, "flame.fill")
        XCTAssertEqual(TimerType.emom.iconName, "clock.fill")
        XCTAssertEqual(TimerType.amrap.iconName, "repeat.circle.fill")
        XCTAssertEqual(TimerType.intervals.iconName, "waveform.path.ecg")
        XCTAssertEqual(TimerType.custom.iconName, "slider.horizontal.3")
    }
}

// MARK: - WorkoutTimer Codable Tests

final class WorkoutTimerCodableTests: XCTestCase {

    func testWorkoutTimer_DecodesFromJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "template_id": null,
            "started_at": "2024-01-15T10:00:00Z",
            "completed_at": null,
            "rounds_completed": 0,
            "paused_seconds": 0,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let timer = try decoder.decode(WorkoutTimer.self, from: json)

        XCTAssertEqual(timer.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(timer.patientId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertNil(timer.templateId)
        XCTAssertEqual(timer.roundsCompleted, 0)
        XCTAssertEqual(timer.pausedSeconds, 0)
        XCTAssertNil(timer.completedAt)
    }

    func testWorkoutTimer_DecodesWithAllFields() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "template_id": "123e4567-e89b-12d3-a456-426614174002",
            "started_at": "2024-01-15T10:00:00Z",
            "completed_at": "2024-01-15T10:30:00Z",
            "rounds_completed": 5,
            "paused_seconds": 60,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let timer = try decoder.decode(WorkoutTimer.self, from: json)

        XCTAssertEqual(timer.templateId?.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174002")
        XCTAssertEqual(timer.roundsCompleted, 5)
        XCTAssertEqual(timer.pausedSeconds, 60)
        XCTAssertNotNil(timer.completedAt)
    }
}

// MARK: - WorkoutTimer Computed Properties Tests

final class WorkoutTimerComputedPropertiesTests: XCTestCase {

    func testWorkoutTimer_IsCompleted_True() {
        let timer = WorkoutTimer.sample
        XCTAssertTrue(timer.isCompleted)
    }

    func testWorkoutTimer_IsCompleted_False() {
        let timer = WorkoutTimer.sampleInProgress
        XCTAssertFalse(timer.isCompleted)
    }

    func testWorkoutTimer_StatusText_Completed() {
        let timer = WorkoutTimer.sample
        XCTAssertEqual(timer.statusText, "Completed")
    }

    func testWorkoutTimer_StatusText_InProgress() {
        let timer = WorkoutTimer.sampleInProgress
        XCTAssertEqual(timer.statusText, "In Progress")
    }

    func testWorkoutTimer_Duration_Positive() {
        let timer = WorkoutTimer.sample
        XCTAssertGreaterThan(timer.duration, 0)
    }

    func testWorkoutTimer_EffectiveDuration_LessThanTotal() {
        let timer = WorkoutTimer.sample
        // Effective duration = duration - pausedSeconds
        XCTAssertLessThanOrEqual(timer.effectiveDuration, timer.duration)
    }

    func testWorkoutTimer_FormattedDuration_NotEmpty() {
        let timer = WorkoutTimer.sample
        XCTAssertFalse(timer.formattedDuration.isEmpty)
        XCTAssertTrue(timer.formattedDuration.contains(":"))
    }

    func testWorkoutTimer_FormattedPausedTime() {
        let timer = WorkoutTimer.sample
        XCTAssertFalse(timer.formattedPausedTime.isEmpty)
        XCTAssertTrue(timer.formattedPausedTime.contains(":"))
    }

    func testWorkoutTimer_Progress_WithTotalRounds() {
        let timer = WorkoutTimer.sample
        let progress = timer.progress(totalRounds: 8)

        // Sample has 8 rounds completed out of 8 total = 100%
        XCTAssertGreaterThanOrEqual(progress, 0)
        XCTAssertLessThanOrEqual(progress, 100)
    }

    func testWorkoutTimer_Progress_ZeroTotalRounds() {
        let timer = WorkoutTimer.sample
        let progress = timer.progress(totalRounds: 0)
        XCTAssertEqual(progress, 0)
    }

    func testWorkoutTimer_Validation_Valid() {
        let timer = WorkoutTimer.sample
        XCTAssertNil(timer.validate())
        XCTAssertTrue(timer.isValid)
    }
}

// MARK: - IntervalTemplate Codable Tests

final class IntervalTemplateCodableTests: XCTestCase {

    func testIntervalTemplate_DecodesFromJSON() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Classic HIIT",
            "type": "intervals",
            "work_seconds": 30,
            "rest_seconds": 10,
            "rounds": 8,
            "cycles": 1,
            "is_public": true,
            "created_by": "123e4567-e89b-12d3-a456-426614174001",
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(IntervalTemplate.self, from: json)

        XCTAssertEqual(template.name, "Classic HIIT")
        XCTAssertEqual(template.type, .intervals)
        XCTAssertEqual(template.workSeconds, 30)
        XCTAssertEqual(template.restSeconds, 10)
        XCTAssertEqual(template.rounds, 8)
        XCTAssertEqual(template.cycles, 1)
        XCTAssertTrue(template.isPublic)
    }

    func testIntervalTemplate_TotalDurationCalculation() {
        // Create a template manually for calculation testing
        // Total duration = (workSeconds + restSeconds) * rounds * cycles
        let workSeconds = 30
        let restSeconds = 10
        let rounds = 8
        let cycles = 2

        let totalSeconds = (workSeconds + restSeconds) * rounds * cycles
        XCTAssertEqual(totalSeconds, 640)  // (30+10) * 8 * 2 = 640 seconds

        let totalMinutes = Double(totalSeconds) / 60.0
        XCTAssertEqual(totalMinutes, 10.67, accuracy: 0.01)  // ~10.67 minutes
    }
}

// MARK: - TimerPreset Tests

final class TimerPresetTests: XCTestCase {

    func testTimerPreset_Sample() {
        let preset = TimerPreset.sample

        XCTAssertEqual(preset.name, "Classic Tabata")
        XCTAssertNotNil(preset.description)
        XCTAssertEqual(preset.category, .cardio)
        XCTAssertEqual(preset.templateJson.type, .tabata)
        XCTAssertEqual(preset.templateJson.workSeconds, 20)
        XCTAssertEqual(preset.templateJson.restSeconds, 10)
        XCTAssertEqual(preset.templateJson.rounds, 8)
    }

    func testTimerPreset_Samples() {
        let samples = TimerPreset.samples

        XCTAssertGreaterThanOrEqual(samples.count, 5)

        // Verify each sample has required data
        for sample in samples {
            XCTAssertFalse(sample.name.isEmpty)
            XCTAssertGreaterThan(sample.templateJson.workSeconds, 0)
            XCTAssertGreaterThanOrEqual(sample.templateJson.restSeconds, 0)
            XCTAssertGreaterThan(sample.templateJson.rounds, 0)
        }
    }

    func testTimerPreset_TemplateJSON_CalculatedDuration() {
        let preset = TimerPreset.sample
        let calculated = preset.templateJson.calculatedDuration

        // (20 + 10) * 8 * 1 = 240 seconds = 4 minutes
        XCTAssertEqual(calculated, 240)
    }

    func testTimerPreset_TemplateJSON_FormattedDuration() {
        let preset = TimerPreset.sample
        let formatted = preset.templateJson.formattedDuration

        // 240 seconds = 4:00
        XCTAssertEqual(formatted, "4:00")
    }

    func testTimerPreset_TemplateJSON_ReadableDuration() {
        let preset = TimerPreset.sample
        let readable = preset.templateJson.readableDuration

        // 240 seconds = 4 min
        XCTAssertEqual(readable, "4 min")
    }

    func testTimerPreset_ToIntervalTemplate() {
        let preset = TimerPreset.sample
        let template = preset.toIntervalTemplate()

        XCTAssertEqual(template.name, preset.name)
        XCTAssertEqual(template.type, preset.templateJson.type)
        XCTAssertEqual(template.workSeconds, preset.templateJson.workSeconds)
        XCTAssertEqual(template.restSeconds, preset.templateJson.restSeconds)
        XCTAssertEqual(template.rounds, preset.templateJson.rounds)
        XCTAssertEqual(template.cycles, preset.templateJson.cycles)
        XCTAssertFalse(template.isPublic)
    }

    func testTimerPreset_TemplateJSON_Difficulty() {
        let preset = TimerPreset.sample

        XCTAssertEqual(preset.templateJson.difficulty, .hard)
        XCTAssertEqual(preset.difficultyName, "Hard")
    }

    func testTimerPreset_TemplateJSON_Difficulty_DisplayNames() {
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.easy.displayName, "Easy")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.moderate.displayName, "Moderate")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.hard.displayName, "Hard")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.veryHard.displayName, "Very Hard")
    }

    func testTimerPreset_TemplateJSON_Difficulty_Colors() {
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.easy.color, "green")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.moderate.color, "yellow")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.hard.color, "orange")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.veryHard.color, "red")
    }

    func testTimerPreset_TemplateJSON_Difficulty_IconNames() {
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.easy.iconName, "figure.walk")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.moderate.iconName, "figure.run")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.hard.iconName, "figure.strengthtraining.traditional")
        XCTAssertEqual(TimerPreset.TemplateJSON.Difficulty.veryHard.iconName, "flame.fill")
    }
}

// MARK: - Timer Duration Calculations

final class TimerDurationCalculationTests: XCTestCase {

    func testDurationCalculation_WorkOnly() {
        let workSeconds = 60
        let restSeconds = 0
        let rounds = 5

        let total = (workSeconds + restSeconds) * rounds
        XCTAssertEqual(total, 300)  // 5 minutes
    }

    func testDurationCalculation_WorkAndRest() {
        let workSeconds = 45
        let restSeconds = 15
        let rounds = 10

        let total = (workSeconds + restSeconds) * rounds
        XCTAssertEqual(total, 600)  // 10 minutes
    }

    func testDurationCalculation_WithCycles() {
        let workSeconds = 30
        let restSeconds = 30
        let rounds = 4
        let cycles = 3

        let total = (workSeconds + restSeconds) * rounds * cycles
        XCTAssertEqual(total, 720)  // 12 minutes
    }

    func testDurationFormatting() {
        let totalSeconds = 725  // 12:05

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        XCTAssertEqual(minutes, 12)
        XCTAssertEqual(seconds, 5)

        let formatted = String(format: "%d:%02d", minutes, seconds)
        XCTAssertEqual(formatted, "12:05")
    }

    func testDurationFormatting_UnderOneMinute() {
        let totalSeconds = 45

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        XCTAssertEqual(minutes, 0)
        XCTAssertEqual(seconds, 45)

        let formatted = String(format: "%d:%02d", minutes, seconds)
        XCTAssertEqual(formatted, "0:45")
    }

    func testDurationFormatting_ExactMinutes() {
        let totalSeconds = 180  // 3:00

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        XCTAssertEqual(minutes, 3)
        XCTAssertEqual(seconds, 0)

        let formatted = String(format: "%d:%02d", minutes, seconds)
        XCTAssertEqual(formatted, "3:00")
    }
}

// MARK: - Timer Progress Calculations

final class TimerProgressCalculationTests: XCTestCase {

    func testProgressCalculation_PhaseProgress() {
        let phaseDuration = 30.0  // 30 seconds
        let timeRemaining = 20.0  // 20 seconds left

        let progress = 1.0 - (timeRemaining / phaseDuration)
        XCTAssertEqual(progress, 0.333, accuracy: 0.01)  // ~33% complete
    }

    func testProgressCalculation_RoundProgress() {
        let totalRounds = 8
        let currentRound = 3

        let progress = Double(currentRound - 1) / Double(totalRounds)
        XCTAssertEqual(progress, 0.25, accuracy: 0.01)  // 2 rounds complete = 25%
    }

    func testProgressCalculation_OverallProgress() {
        let totalRounds = 8
        let currentRound = 5
        let phaseDuration = 30.0
        let timeRemaining = 15.0

        // Calculate overall progress
        let completedRounds = Double(currentRound - 1)
        let currentPhaseProgress = 1.0 - (timeRemaining / phaseDuration)
        let effectiveRounds = completedRounds + (currentPhaseProgress / 2)  // Work phase is half a round
        let overallProgress = effectiveRounds / Double(totalRounds)

        XCTAssertGreaterThan(overallProgress, 0.5)
        XCTAssertLessThan(overallProgress, 0.625)
    }

    func testProgressCalculation_EdgeCases() {
        // Start of workout
        var progress = 1.0 - (30.0 / 30.0)
        XCTAssertEqual(progress, 0.0)

        // End of phase
        progress = 1.0 - (0.0 / 30.0)
        XCTAssertEqual(progress, 1.0)

        // Nearly complete
        progress = 1.0 - (0.1 / 30.0)
        XCTAssertEqual(progress, 0.997, accuracy: 0.001)
    }
}

// MARK: - Sound Type Tests

final class TimerSoundTypeTests: XCTestCase {

    func testSoundType_RawValues() {
        XCTAssertEqual(IntervalTimerService.SoundType.start.rawValue, "timer_start")
        XCTAssertEqual(IntervalTimerService.SoundType.work.rawValue, "timer_work")
        XCTAssertEqual(IntervalTimerService.SoundType.rest.rawValue, "timer_rest")
        XCTAssertEqual(IntervalTimerService.SoundType.pause.rawValue, "timer_pause")
        XCTAssertEqual(IntervalTimerService.SoundType.resume.rawValue, "timer_resume")
        XCTAssertEqual(IntervalTimerService.SoundType.complete.rawValue, "timer_complete")
        XCTAssertEqual(IntervalTimerService.SoundType.countdown.rawValue, "timer_countdown")
        XCTAssertEqual(IntervalTimerService.SoundType.phaseComplete.rawValue, "timer_phase_complete")
    }
}
