//
//  SessionDecodingTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for Session model decoding edge cases.
//  Tests Session, TodaySessionResponse, and SessionExerciseWithTemplate decoding.
//

import XCTest
@testable import PTPerformance

final class SessionDecodingTests: XCTestCase {

    // MARK: - Test Data

    private let sessionId = UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")!
    private let phaseId = UUID(uuidString: "b2c3d4e5-f6a7-8901-bcde-f12345678901")!
    private let exerciseId = UUID(uuidString: "c3d4e5f6-a7b8-9012-cdef-123456789012")!
    private let templateId = UUID(uuidString: "d4e5f6a7-b8c9-0123-def0-234567890123")!

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    // MARK: - Session Decoding Tests

    // MARK: Test 1: Session with exercises array populated

    func testSessionDecodingWithExercises() throws {
        // Note: exercises is not decoded from JSON (excluded from CodingKeys)
        // It uses default empty array, then is populated programmatically
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Upper Body Strength",
            "sequence": 1,
            "weekday": 1,
            "notes": "Focus on form",
            "created_at": "2025-01-15T10:30:00Z",
            "completed": true,
            "started_at": "2025-01-15T09:00:00Z",
            "completed_at": "2025-01-15T10:30:00Z",
            "total_volume": 15000.5,
            "avg_rpe": 7.5,
            "avg_pain": 2.0,
            "duration_minutes": 45
        }
        """

        let data = json.data(using: .utf8)!
        var session = try decoder.decode(Session.self, from: data)

        // Verify basic fields
        XCTAssertEqual(session.id, sessionId)
        XCTAssertEqual(session.phase_id, phaseId)
        XCTAssertEqual(session.name, "Upper Body Strength")
        XCTAssertEqual(session.sequence, 1)

        // Verify exercises defaults to empty (not decoded from JSON)
        XCTAssertTrue(session.exercises.isEmpty)

        // Manually add exercises (as would happen in app)
        let exercise = Exercise.sampleExercises[0]
        session.exercises = [exercise]
        XCTAssertEqual(session.exercises.count, 1)
        XCTAssertEqual(session.exercises[0].id, exercise.id)
    }

    // MARK: Test 2: Session with empty exercises array

    func testSessionDecodingWithEmptyExercises() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Recovery Day",
            "sequence": 7,
            "weekday": 0
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.name, "Recovery Day")
        XCTAssertEqual(session.sequence, 7)
        XCTAssertTrue(session.exercises.isEmpty)
    }

    // MARK: Test 3: Session with null optional fields

    func testSessionDecodingWithNullOptionalFields() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Minimal Session",
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
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.id, sessionId)
        XCTAssertEqual(session.phase_id, phaseId)
        XCTAssertEqual(session.name, "Minimal Session")
        XCTAssertEqual(session.sequence, 1)

        // All optional fields should be nil
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

    func testSessionDecodingWithMissingOptionalFields() throws {
        // Test with optional fields completely absent from JSON
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Basic Session",
            "sequence": 2
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.name, "Basic Session")
        XCTAssertEqual(session.sequence, 2)
        XCTAssertNil(session.weekday)
        XCTAssertNil(session.notes)
        XCTAssertNil(session.completed)
    }

    // MARK: Test 4: Session with all completion tracking fields populated

    func testSessionDecodingWithAllCompletionFields() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Full Workout Complete",
            "sequence": 3,
            "weekday": 3,
            "notes": "Great session, felt strong",
            "created_at": "2025-01-10T08:00:00Z",
            "completed": true,
            "started_at": "2025-01-15T14:00:00Z",
            "completed_at": "2025-01-15T15:30:00Z",
            "total_volume": 25750.0,
            "avg_rpe": 8.2,
            "avg_pain": 1.5,
            "duration_minutes": 90
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completed, true)
        XCTAssertNotNil(session.started_at)
        XCTAssertNotNil(session.completed_at)
        XCTAssertEqual(session.total_volume, 25750.0)
        XCTAssertEqual(session.avg_rpe, 8.2)
        XCTAssertEqual(session.avg_pain, 1.5)
        XCTAssertEqual(session.duration_minutes, 90)

        // Verify dates parsed correctly
        let calendar = Calendar.current
        let startedComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: session.started_at!)
        XCTAssertEqual(startedComponents.hour, 14)
        XCTAssertEqual(startedComponents.minute, 0)
    }

    // MARK: Test 5: Session with partial completion data

    func testSessionDecodingWithPartialCompletionData() throws {
        // Simulates a workout that was started but not finished
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Interrupted Workout",
            "sequence": 4,
            "weekday": 4,
            "completed": false,
            "started_at": "2025-01-16T16:00:00Z",
            "completed_at": null,
            "total_volume": 8500.0,
            "avg_rpe": 6.0,
            "avg_pain": null,
            "duration_minutes": null
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completed, false)
        XCTAssertNotNil(session.started_at)
        XCTAssertNil(session.completed_at)
        XCTAssertEqual(session.total_volume, 8500.0)
        XCTAssertEqual(session.avg_rpe, 6.0)
        XCTAssertNil(session.avg_pain)
        XCTAssertNil(session.duration_minutes)
    }

    func testSessionDecodingWithOnlyVolumeData() throws {
        // Session with only total_volume tracked
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Volume Only Session",
            "sequence": 5,
            "total_volume": 12000.0
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.total_volume, 12000.0)
        XCTAssertNil(session.completed)
        XCTAssertNil(session.avg_rpe)
        XCTAssertNil(session.duration_minutes)
    }

    // MARK: - TodaySessionResponse Decoding Tests

    // MARK: Test 6: TodaySessionResponse with various combinations

    func testTodaySessionResponseWithFullSession() throws {
        let json = """
        {
            "session": {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "name": "Today's Workout",
                "sequence": 1,
                "weekday": 2,
                "notes": "Leg day focus"
            },
            "exercises": [
                {
                    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
                    "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                    "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                    "sequence": 1,
                    "target_sets": 4,
                    "target_reps": 8,
                    "prescribed_load": 225.0,
                    "load_unit": "lbs",
                    "rest_period_seconds": 120
                }
            ],
            "patient_name": "John Doe",
            "message": "Great day for training!"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TodaySessionResponse.self, from: data)

        XCTAssertNotNil(response.session)
        XCTAssertEqual(response.session?.name, "Today's Workout")
        XCTAssertEqual(response.exercises.count, 1)
        XCTAssertEqual(response.patient_name, "John Doe")
        XCTAssertEqual(response.message, "Great day for training!")
    }

    func testTodaySessionResponseWithNullSession() throws {
        // No session scheduled for today
        let json = """
        {
            "session": null,
            "exercises": [],
            "patient_name": "Jane Smith",
            "message": "Rest day - no workout scheduled"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TodaySessionResponse.self, from: data)

        XCTAssertNil(response.session)
        XCTAssertTrue(response.exercises.isEmpty)
        XCTAssertEqual(response.patient_name, "Jane Smith")
        XCTAssertEqual(response.message, "Rest day - no workout scheduled")
    }

    func testTodaySessionResponseWithNullMessage() throws {
        let json = """
        {
            "session": {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "name": "Morning Session",
                "sequence": 1
            },
            "exercises": [],
            "patient_name": "Mike Johnson",
            "message": null
        }
        """

        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TodaySessionResponse.self, from: data)

        XCTAssertNotNil(response.session)
        XCTAssertNil(response.message)
    }

    func testTodaySessionResponseWithMultipleExercises() throws {
        let json = """
        {
            "session": {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "name": "Full Body",
                "sequence": 1
            },
            "exercises": [
                {
                    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
                    "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                    "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                    "sequence": 1,
                    "target_sets": 3,
                    "target_reps": 10
                },
                {
                    "id": "e5f6a7b8-c9d0-1234-ef01-345678901234",
                    "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                    "exercise_template_id": "f6a7b8c9-d0e1-2345-f012-456789012345",
                    "sequence": 2,
                    "target_sets": 4,
                    "target_reps": 12
                },
                {
                    "id": "a7b8c9d0-e1f2-3456-0123-567890123456",
                    "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                    "exercise_template_id": "b8c9d0e1-f2a3-4567-1234-678901234567",
                    "sequence": 3,
                    "target_sets": 3,
                    "target_reps": 15
                }
            ],
            "patient_name": "Sarah Wilson",
            "message": null
        }
        """

        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TodaySessionResponse.self, from: data)

        XCTAssertEqual(response.exercises.count, 3)
        XCTAssertEqual(response.exercises[0].sequence, 1)
        XCTAssertEqual(response.exercises[1].sequence, 2)
        XCTAssertEqual(response.exercises[2].sequence, 3)
    }

    // MARK: - Session Computed Properties Tests

    // MARK: Test 7: dateDisplay with valid weekday (0-6)

    func testDateDisplayWithValidWeekdays() throws {
        let weekdays = [
            (0, "Sunday"),
            (1, "Monday"),
            (2, "Tuesday"),
            (3, "Wednesday"),
            (4, "Thursday"),
            (5, "Friday"),
            (6, "Saturday")
        ]

        for (weekday, expectedDay) in weekdays {
            let json = """
            {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "name": "Test Session",
                "sequence": 1,
                "weekday": \(weekday)
            }
            """

            let data = json.data(using: .utf8)!
            let session = try decoder.decode(Session.self, from: data)

            XCTAssertEqual(session.dateDisplay, expectedDay, "Weekday \(weekday) should display as \(expectedDay)")
        }
    }

    // MARK: Test 8: dateDisplay with invalid weekday values

    func testDateDisplayWithInvalidWeekday() throws {
        // Test negative weekday
        let jsonNegative = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Negative Weekday",
            "sequence": 3,
            "weekday": -1
        }
        """

        let dataNegative = jsonNegative.data(using: .utf8)!
        let sessionNegative = try decoder.decode(Session.self, from: dataNegative)
        XCTAssertEqual(sessionNegative.dateDisplay, "Day 3", "Invalid weekday should fall back to sequence")

        // Test weekday > 6
        let jsonHigh = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "High Weekday",
            "sequence": 5,
            "weekday": 7
        }
        """

        let dataHigh = jsonHigh.data(using: .utf8)!
        let sessionHigh = try decoder.decode(Session.self, from: dataHigh)
        XCTAssertEqual(sessionHigh.dateDisplay, "Day 5", "Weekday 7 should fall back to sequence")

        // Test very high weekday
        let jsonVeryHigh = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Very High Weekday",
            "sequence": 10,
            "weekday": 100
        }
        """

        let dataVeryHigh = jsonVeryHigh.data(using: .utf8)!
        let sessionVeryHigh = try decoder.decode(Session.self, from: dataVeryHigh)
        XCTAssertEqual(sessionVeryHigh.dateDisplay, "Day 10")
    }

    func testDateDisplayWithNullWeekday() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "No Weekday Session",
            "sequence": 4,
            "weekday": null
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.dateDisplay, "Session 4", "Null weekday should show 'Session {sequence}'")
    }

    // MARK: Test 9: completionStatus and isCompleted computed properties

    func testCompletionStatusCompleted() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Completed Session",
            "sequence": 1,
            "completed": true
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completionStatus, "Completed")
        XCTAssertTrue(session.isCompleted)
    }

    func testCompletionStatusNotCompleted() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Not Completed Session",
            "sequence": 1,
            "completed": false
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completionStatus, "In Progress")
        XCTAssertFalse(session.isCompleted)
    }

    func testCompletionStatusNullCompleted() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Unknown Status Session",
            "sequence": 1,
            "completed": null
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completionStatus, "In Progress")
        XCTAssertFalse(session.isCompleted)
    }

    func testCompletionStatusMissingCompleted() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Missing Completed Field",
            "sequence": 1
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(session.completionStatus, "In Progress")
        XCTAssertFalse(session.isCompleted)
    }

    // MARK: Test 10: Session equality (Hashable conformance)

    func testSessionEquality() throws {
        let json1 = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Session A",
            "sequence": 1,
            "weekday": 1
        }
        """

        let json2 = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Session B Different Name",
            "sequence": 2,
            "weekday": 3
        }
        """

        let data1 = json1.data(using: .utf8)!
        let data2 = json2.data(using: .utf8)!
        let session1 = try decoder.decode(Session.self, from: data1)
        let session2 = try decoder.decode(Session.self, from: data2)

        // Sessions should be equal because they have the same ID
        XCTAssertEqual(session1, session2, "Sessions with same ID should be equal")
    }

    func testSessionInequalityDifferentIds() throws {
        let json1 = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Same Name",
            "sequence": 1
        }
        """

        let json2 = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Same Name",
            "sequence": 1
        }
        """

        let data1 = json1.data(using: .utf8)!
        let data2 = json2.data(using: .utf8)!
        let session1 = try decoder.decode(Session.self, from: data1)
        let session2 = try decoder.decode(Session.self, from: data2)

        XCTAssertNotEqual(session1, session2, "Sessions with different IDs should not be equal")
    }

    func testSessionHashableInSet() throws {
        let json1 = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Session 1",
            "sequence": 1
        }
        """

        let json2 = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Session 2",
            "sequence": 2
        }
        """

        let json3 = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Session 1 Duplicate",
            "sequence": 3
        }
        """

        let data1 = json1.data(using: .utf8)!
        let data2 = json2.data(using: .utf8)!
        let data3 = json3.data(using: .utf8)!
        let session1 = try decoder.decode(Session.self, from: data1)
        let session2 = try decoder.decode(Session.self, from: data2)
        let session3 = try decoder.decode(Session.self, from: data3)

        var sessionSet = Set<Session>()
        sessionSet.insert(session1)
        sessionSet.insert(session2)
        sessionSet.insert(session3) // Same ID as session1, should not increase count

        XCTAssertEqual(sessionSet.count, 2, "Set should contain 2 unique sessions")
    }

    func testSessionHashConsistency() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Test Session",
            "sequence": 1
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)

        var hasher1 = Hasher()
        session.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        session.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        XCTAssertEqual(hash1, hash2, "Same session should produce consistent hash")
    }

    // MARK: - SessionExerciseWithTemplate Decoding Tests

    func testSessionExerciseWithTemplateDecoding() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": 4,
            "target_reps": 8,
            "prescribed_sets": null,
            "prescribed_reps": "8-10",
            "prescribed_load": 185.0,
            "load_unit": "lbs",
            "rest_period_seconds": 120,
            "notes": "Focus on depth",
            "sequence": 1,
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "Back Squat",
                "category": "squat",
                "body_region": "lower"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertEqual(exercise.id, "c3d4e5f6-a7b8-9012-cdef-123456789012")
        XCTAssertEqual(exercise.session_id, "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
        XCTAssertEqual(exercise.exercise_template_id, "d4e5f6a7-b8c9-0123-def0-234567890123")
        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertEqual(exercise.target_reps, 8)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.prescribed_reps, "8-10")
        XCTAssertEqual(exercise.prescribed_load, 185.0)
        XCTAssertEqual(exercise.load_unit, "lbs")
        XCTAssertEqual(exercise.rest_period_seconds, 120)
        XCTAssertEqual(exercise.notes, "Focus on depth")
        XCTAssertEqual(exercise.sequence, 1)

        XCTAssertNotNil(exercise.exercise_templates)
        XCTAssertEqual(exercise.exercise_templates?.name, "Back Squat")
        XCTAssertEqual(exercise.exercise_templates?.category, "squat")
        XCTAssertEqual(exercise.exercise_templates?.body_region, "lower")
    }

    func testSessionExerciseWithNullPrescribedSets() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": 3,
            "target_reps": 10,
            "prescribed_sets": null,
            "prescribed_reps": null,
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": null,
            "notes": null,
            "sequence": null,
            "exercise_templates": null
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertEqual(exercise.target_sets, 3)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertNil(exercise.prescribed_reps)
        XCTAssertNil(exercise.prescribed_load)
        XCTAssertNil(exercise.load_unit)
        XCTAssertNil(exercise.rest_period_seconds)
        XCTAssertNil(exercise.notes)
        XCTAssertNil(exercise.sequence)
        XCTAssertNil(exercise.exercise_templates)
    }

    // MARK: Test: sets computed property

    func testSessionExerciseSetsComputedPropertyWithTargetSets() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": 5,
            "target_reps": 8,
            "prescribed_sets": 3
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        // Should prefer target_sets over prescribed_sets
        XCTAssertEqual(exercise.sets, 5)
    }

    func testSessionExerciseSetsComputedPropertyFallbackToPrescribedSets() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": 4
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        // Should fall back to prescribed_sets when target_sets is null
        XCTAssertEqual(exercise.sets, 4)
    }

    func testSessionExerciseSetsComputedPropertyDefaultsToZero() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": null,
            "target_reps": null,
            "prescribed_sets": null
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        // Should default to 0 when both are null
        XCTAssertEqual(exercise.sets, 0)
    }

    func testSessionExerciseWithTemplateMinimalFields() throws {
        // Only required fields
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123"
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(SessionExerciseWithTemplate.self, from: data)

        XCTAssertEqual(exercise.id, "c3d4e5f6-a7b8-9012-cdef-123456789012")
        XCTAssertNil(exercise.target_sets)
        XCTAssertNil(exercise.prescribed_sets)
        XCTAssertEqual(exercise.sets, 0)
    }

    // MARK: - Exercise Decoding Edge Cases

    func testExerciseDecodingWithAllFields() throws {
        let json = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "sequence": 1,
            "target_sets": 4,
            "target_reps": 10,
            "prescribed_sets": 3,
            "prescribed_reps": "8-12",
            "prescribed_load": 135.0,
            "load_unit": "kg",
            "rest_period_seconds": 90,
            "notes": "Warm up properly",
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "Deadlift",
                "category": "hinge",
                "body_region": "posterior",
                "video_url": "https://example.com/deadlift.mp4",
                "video_thumbnail_url": "https://example.com/deadlift-thumb.jpg",
                "video_duration": 45,
                "form_cues": [
                    {"cue": "Brace core", "timestamp": 5},
                    {"cue": "Drive through heels", "timestamp": 15}
                ],
                "technique_cues": {
                    "setup": ["Feet hip width", "Grip outside knees"],
                    "execution": ["Hinge at hips", "Keep bar close"],
                    "breathing": ["Breathe in at bottom", "Exhale at top"]
                },
                "common_mistakes": "Rounding lower back",
                "safety_notes": "Start with lighter weight"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(Exercise.self, from: data)

        XCTAssertEqual(exercise.id, exerciseId)
        XCTAssertEqual(exercise.target_sets, 4)
        XCTAssertEqual(exercise.target_reps, 10)
        XCTAssertEqual(exercise.sets, 4) // Prefers target_sets
        XCTAssertEqual(exercise.exercise_templates?.name, "Deadlift")
        XCTAssertEqual(exercise.exercise_templates?.hasVideo, true)
        XCTAssertEqual(exercise.exercise_templates?.videoDuration, 45)
        XCTAssertEqual(exercise.exercise_templates?.formCues?.count, 2)
        XCTAssertNotNil(exercise.exercise_templates?.techniqueCues)
        XCTAssertEqual(exercise.exercise_templates?.techniqueCues?.setup.count, 2)
    }

    func testExerciseSetsComputedProperty() throws {
        // Test target_sets preferred over prescribed_sets
        let json1 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": 5,
            "prescribed_sets": 3
        }
        """

        let data1 = json1.data(using: .utf8)!
        let exercise1 = try decoder.decode(Exercise.self, from: data1)
        XCTAssertEqual(exercise1.sets, 5, "Should use target_sets when available")

        // Test fallback to prescribed_sets
        let json2 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_sets": null,
            "prescribed_sets": 3
        }
        """

        let data2 = json2.data(using: .utf8)!
        let exercise2 = try decoder.decode(Exercise.self, from: data2)
        XCTAssertEqual(exercise2.sets, 3, "Should fall back to prescribed_sets")

        // Test default to 0
        let json3 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123"
        }
        """

        let data3 = json3.data(using: .utf8)!
        let exercise3 = try decoder.decode(Exercise.self, from: data3)
        XCTAssertEqual(exercise3.sets, 0, "Should default to 0 when both are nil")
    }

    func testExerciseRepsDisplay() throws {
        // Test target_reps preferred
        let json1 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_reps": 12,
            "prescribed_reps": "8-10"
        }
        """

        let data1 = json1.data(using: .utf8)!
        let exercise1 = try decoder.decode(Exercise.self, from: data1)
        XCTAssertEqual(exercise1.repsDisplay, "12")

        // Test fallback to prescribed_reps
        let json2 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "target_reps": null,
            "prescribed_reps": "6-8"
        }
        """

        let data2 = json2.data(using: .utf8)!
        let exercise2 = try decoder.decode(Exercise.self, from: data2)
        XCTAssertEqual(exercise2.repsDisplay, "6-8")

        // Test default
        let json3 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123"
        }
        """

        let data3 = json3.data(using: .utf8)!
        let exercise3 = try decoder.decode(Exercise.self, from: data3)
        XCTAssertEqual(exercise3.repsDisplay, "0")
    }

    func testExerciseLoadDisplay() throws {
        // With load and unit
        let json1 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "prescribed_load": 225.5,
            "load_unit": "lbs"
        }
        """

        let data1 = json1.data(using: .utf8)!
        let exercise1 = try decoder.decode(Exercise.self, from: data1)
        XCTAssertEqual(exercise1.loadDisplay, "225 lbs")

        // Without load
        let json2 = """
        {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123"
        }
        """

        let data2 = json2.data(using: .utf8)!
        let exercise2 = try decoder.decode(Exercise.self, from: data2)
        XCTAssertEqual(exercise2.loadDisplay, "Bodyweight")
    }

    // MARK: - ExerciseTemplate Video Duration Display Tests

    func testVideoDurationDisplayMinutes() throws {
        let json = """
        {
            "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "Bench Press",
                "video_duration": 125
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(Exercise.self, from: data)

        XCTAssertEqual(exercise.exercise_templates?.videoDurationDisplay, "2:05")
    }

    func testVideoDurationDisplaySecondsOnly() throws {
        let json = """
        {
            "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "Quick Demo",
                "video_duration": 45
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(Exercise.self, from: data)

        XCTAssertEqual(exercise.exercise_templates?.videoDurationDisplay, "45s")
    }

    func testVideoDurationDisplayNil() throws {
        let json = """
        {
            "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "No Video"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(Exercise.self, from: data)

        XCTAssertNil(exercise.exercise_templates?.videoDurationDisplay)
    }

    // MARK: - FormCue Display Time Tests

    func testFormCueDisplayTime() throws {
        let json = """
        {
            "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "exercise_template_id": "d4e5f6a7-b8c9-0123-def0-234567890123",
            "exercise_templates": {
                "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
                "name": "Squat",
                "form_cues": [
                    {"cue": "Setup", "timestamp": 0},
                    {"cue": "Descend", "timestamp": 65},
                    {"cue": "Drive up", "timestamp": null}
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let exercise = try decoder.decode(Exercise.self, from: data)

        let formCues = exercise.exercise_templates?.formCues
        XCTAssertEqual(formCues?.count, 3)
        XCTAssertEqual(formCues?[0].displayTime, "0:00")
        XCTAssertEqual(formCues?[1].displayTime, "1:05")
        XCTAssertNil(formCues?[2].displayTime)
    }

    // MARK: - Error Cases

    func testSessionDecodingInvalidJSON() {
        let invalidJson = "{ invalid json }"
        let data = invalidJson.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Session.self, from: data))
    }

    func testSessionDecodingMissingRequiredFields() throws {
        // 'name' now uses decodeIfPresent with default "Untitled Session"
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "sequence": 1
        }
        """

        let data = json.data(using: .utf8)!
        let session = try decoder.decode(Session.self, from: data)
        XCTAssertEqual(session.name, "Untitled Session", "Missing name should default to 'Untitled Session'")
        XCTAssertEqual(session.sequence, 1)
    }

    func testSessionDecodingInvalidUUID() {
        let json = """
        {
            "id": "not-a-valid-uuid",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Test",
            "sequence": 1
        }
        """

        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(Session.self, from: data))
    }

    func testSessionDecodingInvalidDate() {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "phase_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "name": "Test",
            "sequence": 1,
            "created_at": "not-a-date"
        }
        """

        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(Session.self, from: data))
    }

    func testExerciseDecodingInvalidJSON() {
        let invalidJson = "[]"
        let data = invalidJson.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Exercise.self, from: data))
    }
}
