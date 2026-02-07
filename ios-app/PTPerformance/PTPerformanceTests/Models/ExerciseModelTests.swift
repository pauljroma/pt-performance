//
//  ExerciseModelTests.swift
//  PTPerformanceTests
//
//  Build 456: Unit tests for Exercise model with new fields
//  Tests target_sets, target_reps, prescribed_sets (optional), sets computed property,
//  and repsDisplay computed property
//

import XCTest
@testable import PTPerformance

final class ExerciseModelTests: XCTestCase {

    // MARK: - Test UUIDs

    private let exerciseId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let sessionId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let templateId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    // MARK: - JSON Decoder

    private var decoder: JSONDecoder {
        JSONDecoder()
    }

    private var encoder: JSONEncoder {
        JSONEncoder()
    }

    // MARK: - Decoding Tests for target_sets and prescribed_sets

    func testDecoding_targetSetsPresent_prescribedSetsNull() throws {
        // Build 456: New data format with target_sets present, prescribed_sets null
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": 3,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": "8-10",
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(exercise.target_sets, 3)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 3, "sets should use target_sets when prescribed_sets is null")
    }

    func testDecoding_targetSetsNull_prescribedSetsPresent() throws {
        // Legacy data format: target_sets null, prescribed_sets present
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 4,
            "prescribed_reps": "12-15",
            "prescribed_load": 100.0,
            "load_unit": "lbs",
            "rest_period_seconds": 60,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertNil(exercise.target_sets)
        XCTAssertEqual(exercise.prescribed_sets, 4)
        XCTAssertEqual(exercise.sets, 4, "sets should fall back to prescribed_sets when target_sets is null")
    }

    func testDecoding_bothTargetSetsAndPrescribedSetsPresent() throws {
        // Both present: target_sets should take priority
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": 5,
            "target_reps": 8,
            "prescribed_sets": 3,
            "prescribed_reps": "8-10",
            "prescribed_load": 200.0,
            "load_unit": "lbs",
            "rest_period_seconds": 120,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(exercise.target_sets, 5)
        XCTAssertEqual(exercise.prescribed_sets, 3)
        XCTAssertEqual(exercise.sets, 5, "sets should prefer target_sets over prescribed_sets")
    }

    func testDecoding_bothNull() throws {
        // Both null: should default to 0
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertNil(exercise.target_sets)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 0, "sets should default to 0 when both target_sets and prescribed_sets are null")
    }

    // MARK: - Problematic JSON Test (Build 456 Crash Fix)

    func testDecoding_problematicDatabaseJSON() throws {
        // This is the exact JSON format that caused crashes before Build 456 fix
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": 2,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": "8-10",
            "prescribed_load": 135,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": null,
            "exercise_templates": {
                "id": "33333333-3333-3333-3333-333333333333",
                "name": "Bench Press",
                "category": "push",
                "body_region": "upper",
                "video_url": null,
                "video_thumbnail_url": null,
                "video_duration": null,
                "form_cues": null,
                "technique_cues": null,
                "common_mistakes": null,
                "safety_notes": null
            }
        }
        """

        // This should NOT crash - the fix in Build 456 makes prescribed_sets optional
        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(exercise.id, exerciseId)
        XCTAssertEqual(exercise.target_sets, 2)
        XCTAssertNil(exercise.target_reps)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.prescribed_reps, "8-10")
        XCTAssertEqual(exercise.sets, 2, "sets should use target_sets when prescribed_sets is null")
        XCTAssertEqual(exercise.repsDisplay, "8-10", "repsDisplay should fall back to prescribed_reps when target_reps is null")
        XCTAssertEqual(exercise.exercise_templates?.name, "Bench Press")
    }

    // MARK: - Sets Computed Property Tests

    func testSetsComputedProperty_priorityOrder() {
        // Test 1: target_sets present
        let exercise1 = createExercise(targetSets: 5, prescribedSets: 3)
        XCTAssertEqual(exercise1.sets, 5, "Should use target_sets when both present")

        // Test 2: target_sets nil, prescribed_sets present
        let exercise2 = createExercise(targetSets: nil, prescribedSets: 4)
        XCTAssertEqual(exercise2.sets, 4, "Should fall back to prescribed_sets when target_sets is nil")

        // Test 3: both nil
        let exercise3 = createExercise(targetSets: nil, prescribedSets: nil)
        XCTAssertEqual(exercise3.sets, 0, "Should default to 0 when both are nil")

        // Test 4: target_sets is 0 (explicit zero)
        let exercise4 = createExercise(targetSets: 0, prescribedSets: 3)
        XCTAssertEqual(exercise4.sets, 0, "Should use target_sets even when it's 0")
    }

    func testSetsDisplay() {
        let exercise = createExercise(targetSets: 4, prescribedSets: nil)
        XCTAssertEqual(exercise.setsDisplay, "4 sets")

        let exerciseLegacy = createExercise(targetSets: nil, prescribedSets: 3)
        XCTAssertEqual(exerciseLegacy.setsDisplay, "3 sets")

        let exerciseNoSets = createExercise(targetSets: nil, prescribedSets: nil)
        XCTAssertEqual(exerciseNoSets.setsDisplay, "0 sets")
    }

    // MARK: - RepsDisplay Computed Property Tests

    func testRepsDisplay_targetRepsPresent() {
        let exercise = createExercise(targetReps: 12, prescribedReps: "10-12")
        XCTAssertEqual(exercise.repsDisplay, "12", "Should use target_reps when present")
    }

    func testRepsDisplay_targetRepsNull_prescribedRepsPresent() {
        let exercise = createExercise(targetReps: nil, prescribedReps: "8-10")
        XCTAssertEqual(exercise.repsDisplay, "8-10", "Should fall back to prescribed_reps when target_reps is null")
    }

    func testRepsDisplay_bothNull() {
        let exercise = createExercise(targetReps: nil, prescribedReps: nil)
        XCTAssertEqual(exercise.repsDisplay, "0", "Should default to '0' when both are null")
    }

    func testRepsDisplay_rangeFormat() {
        let exercise = createExercise(targetReps: nil, prescribedReps: "15-20")
        XCTAssertEqual(exercise.repsDisplay, "15-20", "Should preserve range format from prescribed_reps")
    }

    func testRepsDisplay_targetRepsZero() {
        // When target_reps is explicitly 0 (e.g., timed exercise)
        let exercise = createExercise(targetReps: 0, prescribedReps: "10")
        XCTAssertEqual(exercise.repsDisplay, "0", "Should use target_reps even when it's 0")
    }

    // MARK: - LoadDisplay Tests

    func testLoadDisplay_withLoadAndUnit() {
        let exercise = createExercise(load: 135.0, loadUnit: "lbs")
        XCTAssertEqual(exercise.loadDisplay, "135 lbs")
    }

    func testLoadDisplay_withKilograms() {
        let exercise = createExercise(load: 60.0, loadUnit: "kg")
        XCTAssertEqual(exercise.loadDisplay, "60 kg")
    }

    func testLoadDisplay_bodyweight() {
        let exercise = createExercise(load: nil, loadUnit: nil)
        XCTAssertEqual(exercise.loadDisplay, "Bodyweight")
    }

    func testLoadDisplay_loadWithoutUnit() {
        let exercise = createExercise(load: 100.0, loadUnit: nil)
        XCTAssertEqual(exercise.loadDisplay, "Bodyweight", "Should show Bodyweight when unit is missing")
    }

    // MARK: - JSON Encoding/Decoding Round-Trip Tests

    func testEncodingDecodingRoundTrip() throws {
        let original = createExercise(
            targetSets: 4,
            targetReps: 10,
            prescribedSets: 3,
            prescribedReps: "8-12",
            load: 185.0,
            loadUnit: "lbs"
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Exercise.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.session_id, original.session_id)
        XCTAssertEqual(decoded.exercise_template_id, original.exercise_template_id)
        XCTAssertEqual(decoded.sequence, original.sequence)
        XCTAssertEqual(decoded.target_sets, original.target_sets)
        XCTAssertEqual(decoded.target_reps, original.target_reps)
        XCTAssertEqual(decoded.prescribed_sets, original.prescribed_sets)
        XCTAssertEqual(decoded.prescribed_reps, original.prescribed_reps)
        XCTAssertEqual(decoded.prescribed_load, original.prescribed_load)
        XCTAssertEqual(decoded.load_unit, original.load_unit)
        XCTAssertEqual(decoded.rest_period_seconds, original.rest_period_seconds)
        XCTAssertEqual(decoded.notes, original.notes)
    }

    func testEncodingDecodingRoundTrip_withNullFields() throws {
        let original = createExercise(
            targetSets: nil,
            targetReps: nil,
            prescribedSets: nil,
            prescribedReps: nil,
            load: nil,
            loadUnit: nil
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Exercise.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertNil(decoded.target_sets)
        XCTAssertNil(decoded.target_reps)
        XCTAssertNil(decoded.prescribed_sets)
        XCTAssertNil(decoded.prescribed_reps)
        XCTAssertNil(decoded.prescribed_load)
        XCTAssertNil(decoded.load_unit)
    }

    // MARK: - ExerciseTemplate Decoding Tests

    func testExerciseTemplateDecoding_fullData() throws {
        let json = """
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "Barbell Back Squat",
            "category": "squat",
            "body_region": "lower",
            "video_url": "https://example.com/video.mp4",
            "video_thumbnail_url": "https://example.com/thumb.jpg",
            "video_duration": 120,
            "form_cues": [
                {"cue": "Keep chest up", "timestamp": 5},
                {"cue": "Drive through heels", "timestamp": 15}
            ],
            "technique_cues": {
                "setup": ["Feet shoulder-width apart", "Bar on upper back"],
                "execution": ["Descend with control", "Explode up"],
                "breathing": ["Inhale on descent", "Exhale on ascent"]
            },
            "common_mistakes": "Knees caving in, rounding lower back",
            "safety_notes": "Use a spotter for heavy sets"
        }
        """

        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(template.id, templateId)
        XCTAssertEqual(template.name, "Barbell Back Squat")
        XCTAssertEqual(template.category, "squat")
        XCTAssertEqual(template.body_region, "lower")
        XCTAssertEqual(template.videoUrl, "https://example.com/video.mp4")
        XCTAssertEqual(template.videoThumbnailUrl, "https://example.com/thumb.jpg")
        XCTAssertEqual(template.videoDuration, 120)
        XCTAssertEqual(template.commonMistakes, "Knees caving in, rounding lower back")
        XCTAssertEqual(template.safetyNotes, "Use a spotter for heavy sets")
        XCTAssertTrue(template.hasVideo)
        XCTAssertEqual(template.videoDurationDisplay, "2:00")

        // Form cues
        XCTAssertEqual(template.formCues?.count, 2)
        XCTAssertEqual(template.formCues?[0].cue, "Keep chest up")
        XCTAssertEqual(template.formCues?[0].timestamp, 5)
        XCTAssertEqual(template.formCues?[0].displayTime, "0:05")
        XCTAssertEqual(template.formCues?[1].cue, "Drive through heels")
        XCTAssertEqual(template.formCues?[1].timestamp, 15)
        XCTAssertEqual(template.formCues?[1].displayTime, "0:15")

        // Technique cues
        XCTAssertNotNil(template.techniqueCues)
        XCTAssertEqual(template.techniqueCues?.setup.count, 2)
        XCTAssertEqual(template.techniqueCues?.execution.count, 2)
        XCTAssertEqual(template.techniqueCues?.breathing.count, 2)
    }

    func testExerciseTemplateDecoding_minimalData() throws {
        let json = """
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "Push-up",
            "category": null,
            "body_region": null,
            "video_url": null,
            "video_thumbnail_url": null,
            "video_duration": null,
            "form_cues": null,
            "technique_cues": null,
            "common_mistakes": null,
            "safety_notes": null
        }
        """

        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(template.id, templateId)
        XCTAssertEqual(template.name, "Push-up")
        XCTAssertNil(template.category)
        XCTAssertNil(template.body_region)
        XCTAssertNil(template.videoUrl)
        XCTAssertNil(template.videoThumbnailUrl)
        XCTAssertNil(template.videoDuration)
        XCTAssertNil(template.formCues)
        XCTAssertNil(template.techniqueCues)
        XCTAssertNil(template.commonMistakes)
        XCTAssertNil(template.safetyNotes)
        XCTAssertFalse(template.hasVideo)
        XCTAssertNil(template.videoDurationDisplay)
    }

    // MARK: - TechniqueCues Tests

    func testTechniqueCuesDecoding() throws {
        let json = """
        {
            "setup": ["Position 1", "Position 2"],
            "execution": ["Step 1", "Step 2", "Step 3"],
            "breathing": ["Breathe in", "Breathe out"]
        }
        """

        let cues = try decoder.decode(Exercise.TechniqueCues.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(cues.setup.count, 2)
        XCTAssertEqual(cues.setup[0], "Position 1")
        XCTAssertEqual(cues.execution.count, 3)
        XCTAssertEqual(cues.breathing.count, 2)
    }

    func testTechniqueCuesDecoding_emptyArrays() throws {
        let json = """
        {
            "setup": [],
            "execution": [],
            "breathing": []
        }
        """

        let cues = try decoder.decode(Exercise.TechniqueCues.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(cues.setup.count, 0)
        XCTAssertEqual(cues.execution.count, 0)
        XCTAssertEqual(cues.breathing.count, 0)
    }

    func testTechniqueCuesInit() {
        let cues = Exercise.TechniqueCues(
            setup: ["Setup 1"],
            execution: ["Execute 1", "Execute 2"],
            breathing: ["Breathe"]
        )

        XCTAssertEqual(cues.setup.count, 1)
        XCTAssertEqual(cues.execution.count, 2)
        XCTAssertEqual(cues.breathing.count, 1)
    }

    func testTechniqueCuesDefaultInit() {
        let cues = Exercise.TechniqueCues()

        XCTAssertEqual(cues.setup.count, 0)
        XCTAssertEqual(cues.execution.count, 0)
        XCTAssertEqual(cues.breathing.count, 0)
    }

    // MARK: - FormCue Tests

    func testFormCueDecoding() throws {
        let json = """
        {
            "cue": "Keep your back straight",
            "timestamp": 45
        }
        """

        let formCue = try decoder.decode(Exercise.ExerciseTemplate.FormCue.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(formCue.cue, "Keep your back straight")
        XCTAssertEqual(formCue.timestamp, 45)
        XCTAssertEqual(formCue.displayTime, "0:45")
    }

    func testFormCueDecoding_nullTimestamp() throws {
        let json = """
        {
            "cue": "General form tip",
            "timestamp": null
        }
        """

        let formCue = try decoder.decode(Exercise.ExerciseTemplate.FormCue.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(formCue.cue, "General form tip")
        XCTAssertNil(formCue.timestamp)
        XCTAssertNil(formCue.displayTime)
    }

    func testFormCueDisplayTime_multipleMinutes() throws {
        let json = """
        {
            "cue": "Advanced technique",
            "timestamp": 125
        }
        """

        let formCue = try decoder.decode(Exercise.ExerciseTemplate.FormCue.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(formCue.displayTime, "2:05")
    }

    func testFormCueDisplayTime_exactMinute() throws {
        let json = """
        {
            "cue": "At one minute mark",
            "timestamp": 60
        }
        """

        let formCue = try decoder.decode(Exercise.ExerciseTemplate.FormCue.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(formCue.displayTime, "1:00")
    }

    // MARK: - Video Duration Display Tests

    func testVideoDurationDisplay_secondsOnly() {
        let template = createExerciseTemplate(videoDuration: 45)
        XCTAssertEqual(template.videoDurationDisplay, "45s")
    }

    func testVideoDurationDisplay_minutesAndSeconds() {
        let template = createExerciseTemplate(videoDuration: 90)
        XCTAssertEqual(template.videoDurationDisplay, "1:30")
    }

    func testVideoDurationDisplay_exactMinutes() {
        let template = createExerciseTemplate(videoDuration: 180)
        XCTAssertEqual(template.videoDurationDisplay, "3:00")
    }

    func testVideoDurationDisplay_nil() {
        let template = createExerciseTemplate(videoDuration: nil)
        XCTAssertNil(template.videoDurationDisplay)
    }

    // MARK: - Sample Exercises Tests

    func testSampleExercisesExist() {
        XCTAssertFalse(Exercise.sampleExercises.isEmpty)
        XCTAssertEqual(Exercise.sampleExercises.count, 2)
    }

    func testSampleExercisesHaveValidData() {
        for exercise in Exercise.sampleExercises {
            XCTAssertNotNil(exercise.id)
            XCTAssertNotNil(exercise.session_id)
            XCTAssertNotNil(exercise.exercise_template_id)
            XCTAssertNotNil(exercise.sequence)
            XCTAssertNotNil(exercise.target_sets)
            XCTAssertNotNil(exercise.target_reps)
            XCTAssertNotNil(exercise.exercise_templates)
            XCTAssertNotNil(exercise.exercise_templates?.name)
        }
    }

    func testSampleExercisesComputedProperties() {
        let benchPress = Exercise.sampleExercises[0]

        XCTAssertEqual(benchPress.exercise_name, "Bench Press")
        XCTAssertEqual(benchPress.sets, 3)
        XCTAssertEqual(benchPress.repsDisplay, "10")
        XCTAssertEqual(benchPress.loadDisplay, "135 lbs")
        XCTAssertEqual(benchPress.setsDisplay, "3 sets")
        XCTAssertEqual(benchPress.movement_pattern, "push")
        XCTAssertEqual(benchPress.equipment, "upper")
        XCTAssertEqual(benchPress.rest_seconds, 90)
        XCTAssertEqual(benchPress.exercise_order, 1)

        let squat = Exercise.sampleExercises[1]

        XCTAssertEqual(squat.exercise_name, "Squat")
        XCTAssertEqual(squat.sets, 3)
        XCTAssertEqual(squat.repsDisplay, "12")
        XCTAssertEqual(squat.loadDisplay, "185 lbs")
        XCTAssertEqual(squat.setsDisplay, "3 sets")
        XCTAssertEqual(squat.movement_pattern, "squat")
        XCTAssertEqual(squat.rest_seconds, 120)
        XCTAssertEqual(squat.exercise_order, 2)
    }

    // MARK: - Identifiable and Hashable Tests

    func testExerciseIdentifiable() {
        let exercise1 = createExercise(targetSets: 3, prescribedSets: nil)
        let exercise2 = createExercise(targetSets: 4, prescribedSets: nil)

        // Different UUIDs
        let exercises = [exercise1, exercise2]
        XCTAssertEqual(exercises.count, 2)
    }

    func testExerciseHashable() {
        let exercise1 = createExercise(targetSets: 3, prescribedSets: nil)
        let exercise2 = createExercise(targetSets: 4, prescribedSets: nil)

        var exerciseSet = Set<Exercise>()
        exerciseSet.insert(exercise1)
        exerciseSet.insert(exercise2)

        XCTAssertEqual(exerciseSet.count, 2)
    }

    func testExerciseTemplateHashable() {
        let template1 = createExerciseTemplate(name: "Squat")
        let template2 = createExerciseTemplate(name: "Deadlift")

        var templateSet = Set<Exercise.ExerciseTemplate>()
        templateSet.insert(template1)
        templateSet.insert(template2)

        XCTAssertEqual(templateSet.count, 2)
    }

    // MARK: - Backwards Compatibility Tests

    func testPrescribedSetsCompatProperty() {
        // prescribedSetsCompat should return same value as sets for backwards compatibility
        let exercise1 = createExercise(targetSets: 5, prescribedSets: 3)
        XCTAssertEqual(exercise1.prescribedSetsCompat, 5)
        XCTAssertEqual(exercise1.prescribedSetsCompat, exercise1.sets)

        let exercise2 = createExercise(targetSets: nil, prescribedSets: 4)
        XCTAssertEqual(exercise2.prescribedSetsCompat, 4)
        XCTAssertEqual(exercise2.prescribedSetsCompat, exercise2.sets)
    }

    func testRestSecondsProperty() {
        let exercise = createExercise(restPeriodSeconds: 90)
        XCTAssertEqual(exercise.rest_seconds, 90)
        XCTAssertEqual(exercise.rest_period_seconds, 90)
    }

    func testPrescribedLoadUnitProperty() {
        let exercise = createExercise(load: 100.0, loadUnit: "kg")
        XCTAssertEqual(exercise.prescribed_load_unit, "kg")
        XCTAssertEqual(exercise.load_unit, "kg")
    }

    // MARK: - Exercise Order Tests

    func testExerciseOrder_withSequence() {
        let exercise = createExercise(sequence: 5)
        XCTAssertEqual(exercise.exercise_order, 5)
    }

    func testExerciseOrder_nilSequence() throws {
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": null,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(exercise.exercise_order, 0, "exercise_order should default to 0 when sequence is null")
    }

    // MARK: - Database JSON Samples Tests

    func testRealDatabaseJSON_newFormat() throws {
        // Simulating actual database response with new fields
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "session_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "exercise_template_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "sequence": 3,
            "target_sets": 4,
            "target_reps": 8,
            "prescribed_sets": null,
            "prescribed_reps": "6-8",
            "prescribed_load": 225.0,
            "load_unit": "lbs",
            "rest_period_seconds": 180,
            "notes": "Focus on form",
            "exercise_templates": {
                "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
                "name": "Deadlift",
                "category": "hinge",
                "body_region": "posterior",
                "video_url": "https://cdn.ptperformance.com/videos/deadlift.mp4",
                "video_thumbnail_url": "https://cdn.ptperformance.com/thumbs/deadlift.jpg",
                "video_duration": 95,
                "form_cues": [
                    {"cue": "Hinge at hips", "timestamp": 10},
                    {"cue": "Keep bar close", "timestamp": 25},
                    {"cue": "Lock out at top", "timestamp": 40}
                ],
                "technique_cues": {
                    "setup": ["Feet hip-width", "Grip outside knees"],
                    "execution": ["Drive through floor", "Extend hips and knees together"],
                    "breathing": ["Brace before lift", "Exhale at lockout"]
                },
                "common_mistakes": "Rounding lower back, starting with hips too high",
                "safety_notes": "Use lifting belt for heavy sets. Stop if lower back pain occurs."
            }
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        // Core properties
        XCTAssertEqual(exercise.sequence, 3)
        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertEqual(exercise.target_reps, 8)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.notes, "Focus on form")

        // Computed properties
        XCTAssertEqual(exercise.sets, 4)
        XCTAssertEqual(exercise.repsDisplay, "8")
        XCTAssertEqual(exercise.loadDisplay, "225 lbs")
        XCTAssertEqual(exercise.exercise_order, 3)
        XCTAssertEqual(exercise.exercise_name, "Deadlift")

        // Template properties
        let template = exercise.exercise_templates
        XCTAssertNotNil(template)
        XCTAssertTrue(template!.hasVideo)
        XCTAssertEqual(template!.videoDurationDisplay, "1:35")
        XCTAssertEqual(template!.formCues?.count, 3)
        XCTAssertEqual(template!.techniqueCues?.setup.count, 2)
    }

    func testRealDatabaseJSON_legacyFormat() throws {
        // Simulating legacy database response with prescribed_sets
        let json = """
        {
            "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "session_id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
            "exercise_template_id": "f6a7b8c9-d0e1-2345-f012-456789012345",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 3,
            "prescribed_reps": "12-15",
            "prescribed_load": 50.0,
            "load_unit": "lbs",
            "rest_period_seconds": 60,
            "notes": null,
            "exercise_templates": {
                "id": "f6a7b8c9-d0e1-2345-f012-456789012345",
                "name": "Dumbbell Curl",
                "category": "pull",
                "body_region": "upper",
                "video_url": null,
                "video_thumbnail_url": null,
                "video_duration": null,
                "form_cues": null,
                "technique_cues": null,
                "common_mistakes": null,
                "safety_notes": null
            }
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        // Legacy format should still work
        XCTAssertNil(exercise.target_sets)
        XCTAssertNil(exercise.target_reps)
        XCTAssertEqual(exercise.prescribed_sets, 3)
        XCTAssertEqual(exercise.prescribed_reps, "12-15")

        // Computed properties should fall back correctly
        XCTAssertEqual(exercise.sets, 3, "Should fall back to prescribed_sets")
        XCTAssertEqual(exercise.repsDisplay, "12-15", "Should fall back to prescribed_reps")
        XCTAssertEqual(exercise.exercise_name, "Dumbbell Curl")
        XCTAssertFalse(exercise.exercise_templates!.hasVideo)
    }

    // MARK: - Edge Cases

    func testDecodingWithEmptyStrings() throws {
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 1,
            "target_sets": 3,
            "target_reps": null,
            "prescribed_sets": null,
            "prescribed_reps": "",
            "prescribed_load": null,
            "load_unit": "",
            "rest_period_seconds": null,
            "notes": "",
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(exercise.prescribed_reps, "")
        XCTAssertEqual(exercise.load_unit, "")
        XCTAssertEqual(exercise.notes, "")
        // repsDisplay should use target_reps when available, even if prescribed_reps is empty
        XCTAssertEqual(exercise.repsDisplay, "", "Empty prescribed_reps since target_reps is nil")
    }

    func testDecodingWithZeroValues() throws {
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "session_id": "22222222-2222-2222-2222-222222222222",
            "exercise_template_id": "33333333-3333-3333-3333-333333333333",
            "sequence": 0,
            "target_sets": 0,
            "target_reps": 0,
            "prescribed_sets": 0,
            "prescribed_reps": "0",
            "prescribed_load": 0.0,
            "load_unit": "lbs",
            "rest_period_seconds": 0,
            "notes": null,
            "exercise_templates": null
        }
        """

        let exercise = try decoder.decode(Exercise.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(exercise.target_sets, 0)
        XCTAssertEqual(exercise.target_reps, 0)
        XCTAssertEqual(exercise.sets, 0)
        XCTAssertEqual(exercise.repsDisplay, "0")
        XCTAssertEqual(exercise.loadDisplay, "0 lbs")
        XCTAssertEqual(exercise.exercise_order, 0)
    }

    // MARK: - Helper Methods

    private func createExercise(
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        prescribedSets: Int? = nil,
        prescribedReps: String? = nil,
        load: Double? = nil,
        loadUnit: String? = nil,
        restPeriodSeconds: Int? = 90,
        sequence: Int? = 1
    ) -> Exercise {
        Exercise(
            id: UUID(),
            session_id: sessionId,
            exercise_template_id: templateId,
            sequence: sequence,
            target_sets: targetSets,
            target_reps: targetReps,
            prescribed_sets: prescribedSets,
            prescribed_reps: prescribedReps,
            prescribed_load: load,
            load_unit: loadUnit,
            rest_period_seconds: restPeriodSeconds,
            notes: nil,
            exercise_templates: nil
        )
    }

    private func createExerciseTemplate(
        name: String = "Test Exercise",
        category: String? = "strength",
        bodyRegion: String? = "full",
        videoUrl: String? = nil,
        videoDuration: Int? = nil
    ) -> Exercise.ExerciseTemplate {
        Exercise.ExerciseTemplate(
            id: UUID(),
            name: name,
            category: category,
            body_region: bodyRegion,
            videoUrl: videoUrl,
            videoThumbnailUrl: nil,
            videoDuration: videoDuration,
            formCues: nil,
            techniqueCues: nil,
            commonMistakes: nil,
            safetyNotes: nil
        )
    }
}
