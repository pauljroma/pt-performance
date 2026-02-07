//
//  SessionServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for Session model and service layer
//  Tests today's session fetching, exercise decoding, empty exercises handling, and error cases
//

import XCTest
@testable import PTPerformance

// MARK: - Session Model Tests

final class SessionModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSession_BasicInitialization() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Upper Body Strength",
            "sequence": 1,
            "weekday": 1,
            "notes": "Focus on chest and shoulders",
            "created_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(session.phase_id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertEqual(session.name, "Upper Body Strength")
        XCTAssertEqual(session.sequence, 1)
        XCTAssertEqual(session.weekday, 1)
        XCTAssertEqual(session.notes, "Focus on chest and shoulders")
        XCTAssertNotNil(session.created_at)
    }

    func testSession_WithCompletionData() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Lower Body Day",
            "sequence": 2,
            "weekday": 3,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "completed": true,
            "started_at": "2024-01-17T09:00:00Z",
            "completed_at": "2024-01-17T10:30:00Z",
            "total_volume": 15000.0,
            "avg_rpe": 7.5,
            "avg_pain": 1.0,
            "duration_minutes": 90
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertTrue(session.completed == true)
        XCTAssertNotNil(session.started_at)
        XCTAssertNotNil(session.completed_at)
        XCTAssertEqual(session.total_volume, 15000.0)
        XCTAssertEqual(session.avg_rpe, 7.5)
        XCTAssertEqual(session.avg_pain, 1.0)
        XCTAssertEqual(session.duration_minutes, 90)
    }

    func testSession_WithNullOptionalFields() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Basic Session",
            "sequence": 1,
            "weekday": null,
            "notes": null,
            "created_at": null,
            "completed": null,
            "started_at": null,
            "completed_at": null,
            "total_volume": null,
            "avg_rpe": null,
            "avg_pain": null,
            "duration_minutes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertNil(session.weekday)
        XCTAssertNil(session.notes)
        XCTAssertNil(session.created_at)
        XCTAssertNil(session.completed)
        XCTAssertNil(session.started_at)
        XCTAssertNil(session.completed_at)
        XCTAssertNil(session.total_volume)
        XCTAssertNil(session.avg_rpe)
        XCTAssertNil(session.avg_pain)
        XCTAssertNil(session.duration_minutes)
    }

    // MARK: - Computed Properties Tests

    func testSession_DateDisplay_WithValidWeekday() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Monday Workout",
            "sequence": 1,
            "weekday": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.dateDisplay, "Monday")
    }

    func testSession_DateDisplay_AllWeekdays() throws {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for (index, expectedDay) in days.enumerated() {
            let json = """
            {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "phase_id": "123e4567-e89b-12d3-a456-426614174001",
                "name": "Test Session",
                "sequence": 1,
                "weekday": \(index)
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            let session = try decoder.decode(Session.self, from: json)

            XCTAssertEqual(session.dateDisplay, expectedDay, "Weekday \(index) should display as \(expectedDay)")
        }
    }

    func testSession_DateDisplay_WithNilWeekday() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Test Session",
            "sequence": 5,
            "weekday": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.dateDisplay, "Session 5")
    }

    func testSession_CompletionStatus_Completed() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Completed Session",
            "sequence": 1,
            "completed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.completionStatus, "Completed")
        XCTAssertTrue(session.isCompleted)
    }

    func testSession_CompletionStatus_InProgress() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "In Progress Session",
            "sequence": 1,
            "completed": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.completionStatus, "In Progress")
        XCTAssertFalse(session.isCompleted)
    }

    func testSession_CompletionStatus_NilCompleted() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "New Session",
            "sequence": 1,
            "completed": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.completionStatus, "In Progress")
        XCTAssertFalse(session.isCompleted)
    }

    // MARK: - Hashable/Equatable Tests

    func testSession_Hashable() throws {
        let json1 = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session 1",
            "sequence": 1
        }
        """.data(using: .utf8)!

        let json2 = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174002",
            "name": "Different Name",
            "sequence": 2
        }
        """.data(using: .utf8)!

        let json3 = """
        {
            "id": "223e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session 1",
            "sequence": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session1 = try decoder.decode(Session.self, from: json1)
        let session2 = try decoder.decode(Session.self, from: json2)
        let session3 = try decoder.decode(Session.self, from: json3)

        // Same ID should be equal (despite different other fields)
        XCTAssertEqual(session1, session2)
        XCTAssertEqual(session1.hashValue, session2.hashValue)

        // Different ID should not be equal
        XCTAssertNotEqual(session1, session3)
    }

    // MARK: - Exercises Array Tests

    func testSession_ExercisesDefaultEmpty() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session Without Exercises",
            "sequence": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(Session.self, from: json)

        // Exercises should default to empty array
        XCTAssertTrue(session.exercises.isEmpty)
    }
}

// MARK: - Exercise Model Tests

final class SessionExerciseModelTests: XCTestCase {

    func testExercise_BasicDecode() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_id": "123e4567-e89b-12d3-a456-426614174001",
            "exercise_template_id": "123e4567-e89b-12d3-a456-426614174002",
            "sequence": 1,
            "target_sets": 4,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": "8-10",
            "prescribed_load": 135.0,
            "load_unit": "lbs",
            "rest_period_seconds": 90,
            "notes": "Keep core tight",
            "exercise_templates": {
                "id": "123e4567-e89b-12d3-a456-426614174002",
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
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let exercise = try decoder.decode(Exercise.self, from: json)

        XCTAssertEqual(exercise.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(exercise.session_id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertEqual(exercise.exercise_template_id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174002")
        XCTAssertEqual(exercise.sequence, 1)
        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertEqual(exercise.target_reps, 10)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.prescribed_reps, "8-10")
        XCTAssertEqual(exercise.prescribed_load, 135.0)
        XCTAssertEqual(exercise.load_unit, "lbs")
        XCTAssertEqual(exercise.rest_period_seconds, 90)
        XCTAssertEqual(exercise.notes, "Keep core tight")
    }

    func testExercise_ComputedProperties() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_id": "123e4567-e89b-12d3-a456-426614174001",
            "exercise_template_id": "123e4567-e89b-12d3-a456-426614174002",
            "sequence": 2,
            "target_sets": 3,
            "target_reps": 12,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": 185.0,
            "load_unit": "lbs",
            "rest_period_seconds": 120,
            "notes": null,
            "exercise_templates": {
                "id": "123e4567-e89b-12d3-a456-426614174002",
                "name": "Squat",
                "category": "squat",
                "body_region": "lower",
                "video_url": "https://example.com/squat.mp4",
                "video_thumbnail_url": "https://example.com/squat-thumb.jpg",
                "video_duration": 45,
                "form_cues": null,
                "technique_cues": null,
                "common_mistakes": "Knees caving in",
                "safety_notes": "Use a spotter"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let exercise = try decoder.decode(Exercise.self, from: json)

        // Test computed properties
        XCTAssertEqual(exercise.exercise_order, 2)
        XCTAssertEqual(exercise.exercise_name, "Squat")
        XCTAssertEqual(exercise.movement_pattern, "squat")
        XCTAssertEqual(exercise.equipment, "lower")
        XCTAssertEqual(exercise.sets, 3)  // Should use target_sets
        XCTAssertEqual(exercise.repsDisplay, "12")  // Should use target_reps
        XCTAssertEqual(exercise.loadDisplay, "185 lbs")
        XCTAssertEqual(exercise.setsDisplay, "3 sets")
        XCTAssertEqual(exercise.rest_seconds, 120)
        XCTAssertEqual(exercise.prescribed_load_unit, "lbs")
    }

    func testExercise_SetsFallback() throws {
        // Test that sets falls back to prescribed_sets when target_sets is nil
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_id": "123e4567-e89b-12d3-a456-426614174001",
            "exercise_template_id": "123e4567-e89b-12d3-a456-426614174002",
            "sequence": 1,
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 4,
            "prescribed_reps": "10-12",
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "exercise_templates": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let exercise = try decoder.decode(Exercise.self, from: json)

        XCTAssertEqual(exercise.sets, 4)  // Should use prescribed_sets as fallback
        XCTAssertEqual(exercise.repsDisplay, "10-12")  // Should use prescribed_reps
        XCTAssertEqual(exercise.loadDisplay, "Bodyweight")  // No load specified
    }

    func testExercise_SequenceNil() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_id": "123e4567-e89b-12d3-a456-426614174001",
            "exercise_template_id": "123e4567-e89b-12d3-a456-426614174002",
            "sequence": null,
            "target_sets": 3,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "exercise_templates": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let exercise = try decoder.decode(Exercise.self, from: json)

        XCTAssertNil(exercise.sequence)
        XCTAssertEqual(exercise.exercise_order, 0)  // Default when sequence is nil
    }
}

// MARK: - Exercise Template Tests

final class ExerciseTemplateTests: XCTestCase {

    func testExerciseTemplate_WithVideo() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Romanian Deadlift",
            "category": "hinge",
            "body_region": "posterior chain",
            "video_url": "https://cdn.example.com/rdl.mp4",
            "video_thumbnail_url": "https://cdn.example.com/rdl-thumb.jpg",
            "video_duration": 120,
            "form_cues": [
                {"cue": "Hinge at hips", "timestamp": 5},
                {"cue": "Keep back flat", "timestamp": 15}
            ],
            "technique_cues": {
                "setup": ["Stand with feet hip-width apart", "Grip bar outside thighs"],
                "execution": ["Push hips back", "Lower until hamstrings stretch"],
                "breathing": ["Inhale on descent", "Exhale on ascent"]
            },
            "common_mistakes": "Rounding lower back",
            "safety_notes": "Start light to learn form"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json)

        XCTAssertEqual(template.name, "Romanian Deadlift")
        XCTAssertEqual(template.category, "hinge")
        XCTAssertEqual(template.body_region, "posterior chain")
        XCTAssertEqual(template.videoUrl, "https://cdn.example.com/rdl.mp4")
        XCTAssertEqual(template.videoThumbnailUrl, "https://cdn.example.com/rdl-thumb.jpg")
        XCTAssertEqual(template.videoDuration, 120)
        XCTAssertTrue(template.hasVideo)
        XCTAssertEqual(template.videoDurationDisplay, "2:00")

        // Form cues
        XCTAssertEqual(template.formCues?.count, 2)
        XCTAssertEqual(template.formCues?[0].cue, "Hinge at hips")
        XCTAssertEqual(template.formCues?[0].timestamp, 5)
        XCTAssertEqual(template.formCues?[0].displayTime, "0:05")

        // Technique cues
        XCTAssertEqual(template.techniqueCues?.setup.count, 2)
        XCTAssertEqual(template.techniqueCues?.execution.count, 2)
        XCTAssertEqual(template.techniqueCues?.breathing.count, 2)

        XCTAssertEqual(template.commonMistakes, "Rounding lower back")
        XCTAssertEqual(template.safetyNotes, "Start light to learn form")
    }

    func testExerciseTemplate_WithoutVideo() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Plank",
            "category": "core",
            "body_region": "full body",
            "video_url": null,
            "video_thumbnail_url": null,
            "video_duration": null,
            "form_cues": null,
            "technique_cues": null,
            "common_mistakes": null,
            "safety_notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json)

        XCTAssertFalse(template.hasVideo)
        XCTAssertNil(template.videoUrl)
        XCTAssertNil(template.videoDurationDisplay)
    }

    func testExerciseTemplate_VideoDurationDisplay_ShortVideo() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Quick Demo",
            "category": "demo",
            "body_region": null,
            "video_url": "https://example.com/demo.mp4",
            "video_thumbnail_url": null,
            "video_duration": 45,
            "form_cues": null,
            "technique_cues": null,
            "common_mistakes": null,
            "safety_notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json)

        // Under 1 minute uses "Xs" format, not "M:SS"
        XCTAssertEqual(template.videoDurationDisplay, "45s")
    }

    func testExerciseTemplate_VideoDurationDisplay_UnderMinute() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Very Short",
            "category": "demo",
            "body_region": null,
            "video_url": "https://example.com/short.mp4",
            "video_thumbnail_url": null,
            "video_duration": 15,
            "form_cues": null,
            "technique_cues": null,
            "common_mistakes": null,
            "safety_notes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let template = try decoder.decode(Exercise.ExerciseTemplate.self, from: json)

        XCTAssertEqual(template.videoDurationDisplay, "15s")
    }

    func testFormCue_DisplayTime_NilTimestamp() {
        let cue = Exercise.ExerciseTemplate.FormCue(cue: "Test cue", timestamp: nil)
        XCTAssertNil(cue.displayTime)
    }

    func testFormCue_DisplayTime_WithTimestamp() {
        let cue = Exercise.ExerciseTemplate.FormCue(cue: "Test cue", timestamp: 125)
        XCTAssertEqual(cue.displayTime, "2:05")
    }
}

// MARK: - TechniqueCues Tests

final class TechniqueCuesTests: XCTestCase {

    func testTechniqueCues_DefaultInit() {
        let cues = Exercise.TechniqueCues()

        XCTAssertTrue(cues.setup.isEmpty)
        XCTAssertTrue(cues.execution.isEmpty)
        XCTAssertTrue(cues.breathing.isEmpty)
    }

    func testTechniqueCues_CustomInit() {
        let cues = Exercise.TechniqueCues(
            setup: ["Stand tall", "Grip bar"],
            execution: ["Push through heels", "Drive hips forward"],
            breathing: ["Brace core", "Exhale at top"]
        )

        XCTAssertEqual(cues.setup.count, 2)
        XCTAssertEqual(cues.execution.count, 2)
        XCTAssertEqual(cues.breathing.count, 2)
    }

    func testTechniqueCues_DecodesFromJSON() throws {
        let json = """
        {
            "setup": ["Step 1", "Step 2"],
            "execution": ["Move 1", "Move 2", "Move 3"],
            "breathing": ["Breathe in"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let cues = try decoder.decode(Exercise.TechniqueCues.self, from: json)

        XCTAssertEqual(cues.setup, ["Step 1", "Step 2"])
        XCTAssertEqual(cues.execution, ["Move 1", "Move 2", "Move 3"])
        XCTAssertEqual(cues.breathing, ["Breathe in"])
    }
}

// MARK: - TodaySessionResponse Tests

final class TodaySessionResponseTests: XCTestCase {

    func testTodaySessionResponse_WithSession() throws {
        let json = """
        {
            "session": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "phase_id": "123e4567-e89b-12d3-a456-426614174001",
                "name": "Today's Workout",
                "sequence": 1,
                "weekday": 3,
                "notes": null,
                "created_at": null
            },
            "exercises": [
                {
                    "id": "223e4567-e89b-12d3-a456-426614174000",
                    "session_id": "123e4567-e89b-12d3-a456-426614174000",
                    "exercise_template_id": "323e4567-e89b-12d3-a456-426614174000",
                    "sequence": 1,
                    "target_sets": 3,
                    "target_reps": 10,
                    "prescribed_sets": null,
                    "prescribed_reps": null,
                    "prescribed_load": null,
                    "load_unit": null,
                    "rest_period_seconds": null,
                    "notes": null,
                    "exercise_templates": null
                }
            ],
            "patient_name": "John Doe",
            "message": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(TodaySessionResponse.self, from: json)

        XCTAssertNotNil(response.session)
        XCTAssertEqual(response.session?.name, "Today's Workout")
        XCTAssertEqual(response.exercises.count, 1)
        XCTAssertEqual(response.patient_name, "John Doe")
        XCTAssertNil(response.message)
    }

    func testTodaySessionResponse_NoSessionToday() throws {
        let json = """
        {
            "session": null,
            "exercises": [],
            "patient_name": "Jane Smith",
            "message": "Rest day - no workout scheduled"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(TodaySessionResponse.self, from: json)

        XCTAssertNil(response.session)
        XCTAssertTrue(response.exercises.isEmpty)
        XCTAssertEqual(response.patient_name, "Jane Smith")
        XCTAssertEqual(response.message, "Rest day - no workout scheduled")
    }

    func testTodaySessionResponse_WithMultipleExercises() throws {
        let json = """
        {
            "session": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "phase_id": "123e4567-e89b-12d3-a456-426614174001",
                "name": "Full Body",
                "sequence": 1,
                "weekday": null,
                "notes": null,
                "created_at": null
            },
            "exercises": [
                {
                    "id": "223e4567-e89b-12d3-a456-426614174001",
                    "session_id": "123e4567-e89b-12d3-a456-426614174000",
                    "exercise_template_id": "323e4567-e89b-12d3-a456-426614174001",
                    "sequence": 1,
                    "target_sets": 4,
                    "target_reps": 8,
                    "prescribed_sets": null,
                    "prescribed_reps": null,
                    "prescribed_load": 225.0,
                    "load_unit": "lbs",
                    "rest_period_seconds": 180,
                    "notes": null,
                    "exercise_templates": null
                },
                {
                    "id": "223e4567-e89b-12d3-a456-426614174002",
                    "session_id": "123e4567-e89b-12d3-a456-426614174000",
                    "exercise_template_id": "323e4567-e89b-12d3-a456-426614174002",
                    "sequence": 2,
                    "target_sets": 3,
                    "target_reps": 12,
                    "prescribed_sets": null,
                    "prescribed_reps": null,
                    "prescribed_load": 135.0,
                    "load_unit": "lbs",
                    "rest_period_seconds": 90,
                    "notes": null,
                    "exercise_templates": null
                },
                {
                    "id": "223e4567-e89b-12d3-a456-426614174003",
                    "session_id": "123e4567-e89b-12d3-a456-426614174000",
                    "exercise_template_id": "323e4567-e89b-12d3-a456-426614174003",
                    "sequence": 3,
                    "target_sets": 3,
                    "target_reps": 15,
                    "prescribed_sets": null,
                    "prescribed_reps": null,
                    "prescribed_load": null,
                    "load_unit": null,
                    "rest_period_seconds": 60,
                    "notes": "Bodyweight only",
                    "exercise_templates": null
                }
            ],
            "patient_name": "Test Patient",
            "message": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(TodaySessionResponse.self, from: json)

        XCTAssertEqual(response.exercises.count, 3)
        XCTAssertEqual(response.exercises[0].sequence, 1)
        XCTAssertEqual(response.exercises[1].sequence, 2)
        XCTAssertEqual(response.exercises[2].sequence, 3)
    }
}

// MARK: - Sample Data Tests

final class SessionSampleDataTests: XCTestCase {

    func testExercise_SampleExercises() {
        let samples = Exercise.sampleExercises

        XCTAssertEqual(samples.count, 2)

        // First sample - Bench Press
        let benchPress = samples[0]
        XCTAssertEqual(benchPress.sequence, 1)
        XCTAssertEqual(benchPress.target_sets, 3)
        XCTAssertEqual(benchPress.target_reps, 10)
        XCTAssertEqual(benchPress.prescribed_load, 135)
        XCTAssertEqual(benchPress.load_unit, "lbs")
        XCTAssertEqual(benchPress.rest_period_seconds, 90)
        XCTAssertEqual(benchPress.exercise_templates?.name, "Bench Press")
        XCTAssertEqual(benchPress.exercise_templates?.category, "push")
        XCTAssertEqual(benchPress.exercise_templates?.body_region, "upper")

        // Second sample - Squat
        let squat = samples[1]
        XCTAssertEqual(squat.sequence, 2)
        XCTAssertEqual(squat.target_sets, 3)
        XCTAssertEqual(squat.target_reps, 12)
        XCTAssertEqual(squat.prescribed_load, 185)
        XCTAssertEqual(squat.exercise_templates?.name, "Squat")
        XCTAssertEqual(squat.exercise_templates?.category, "squat")
    }
}

// MARK: - Empty Exercises Handling Tests

final class EmptyExercisesHandlingTests: XCTestCase {

    func testSession_EmptyExercises_ValidSession() throws {
        let json = """
        {
            "session": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "phase_id": "123e4567-e89b-12d3-a456-426614174001",
                "name": "Empty Session",
                "sequence": 1
            },
            "exercises": [],
            "patient_name": "Test",
            "message": "Session has no exercises configured"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(TodaySessionResponse.self, from: json)

        XCTAssertNotNil(response.session)
        XCTAssertTrue(response.exercises.isEmpty)
        XCTAssertEqual(response.message, "Session has no exercises configured")
    }

    func testSession_NullExercisesField_Fails() {
        // exercises is a required field, null should fail
        let json = """
        {
            "session": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "phase_id": "123e4567-e89b-12d3-a456-426614174001",
                "name": "Session",
                "sequence": 1
            },
            "exercises": null,
            "patient_name": "Test",
            "message": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(TodaySessionResponse.self, from: json))
    }
}

// MARK: - Error Handling Tests

final class SessionErrorHandlingTests: XCTestCase {

    func testSession_MissingRequiredField_Throws() {
        // Missing 'sequence' field
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Incomplete Session"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(Session.self, from: json)) { error in
            if case DecodingError.keyNotFound(let key, _) = error {
                XCTAssertEqual(key.stringValue, "sequence")
            } else {
                XCTFail("Expected keyNotFound error for 'sequence'")
            }
        }
    }

    func testSession_InvalidUUID_Throws() {
        let json = """
        {
            "id": "not-a-valid-uuid",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session",
            "sequence": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(Session.self, from: json))
    }

    func testSession_InvalidSequenceType_Throws() {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session",
            "sequence": "first"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(Session.self, from: json)) { error in
            if case DecodingError.typeMismatch = error {
                // Expected
            } else {
                XCTFail("Expected typeMismatch error")
            }
        }
    }

    func testExercise_InvalidLoadType_Throws() {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "session_id": "123e4567-e89b-12d3-a456-426614174001",
            "exercise_template_id": "123e4567-e89b-12d3-a456-426614174002",
            "sequence": 1,
            "target_sets": 3,
            "target_reps": 10,
            "prescribed_load": "heavy",
            "load_unit": "lbs"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(Exercise.self, from: json))
    }
}

// MARK: - Flexible Decoder Tests

final class SessionFlexibleDecoderTests: XCTestCase {

    func testSession_FlexibleDecoder_ISO8601WithFractionalSeconds() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session",
            "sequence": 1,
            "created_at": "2024-01-15T10:30:00.123456+00:00"
        }
        """.data(using: .utf8)!

        let session = try PTSupabaseClient.flexibleDecoder.decode(Session.self, from: json)

        XCTAssertNotNil(session.created_at)
    }

    func testSession_FlexibleDecoder_SimpleDateFormat() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session",
            "sequence": 1,
            "created_at": "2024-01-15"
        }
        """.data(using: .utf8)!

        let session = try PTSupabaseClient.flexibleDecoder.decode(Session.self, from: json)

        XCTAssertNotNil(session.created_at)
    }

    func testSession_FlexibleDecoder_StandardISO8601() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "phase_id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Session",
            "sequence": 1,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let session = try PTSupabaseClient.flexibleDecoder.decode(Session.self, from: json)

        XCTAssertNotNil(session.created_at)
    }
}
