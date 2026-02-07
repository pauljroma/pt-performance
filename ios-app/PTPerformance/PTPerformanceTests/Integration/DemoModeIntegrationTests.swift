//
//  DemoModeIntegrationTests.swift
//  PTPerformanceTests
//
//  Integration tests for demo mode functionality.
//  Tests data decoding and model integrity for seeded demo accounts.
//
//  Demo Patient ID: 00000000-0000-0000-0000-000000000001
//  Demo Therapist ID: 00000000-0000-0000-0000-000000000002
//

import XCTest
@testable import PTPerformance

// MARK: - Demo Patient Integration Tests

final class DemoPatientIntegrationTests: XCTestCase {

    // MARK: - Test 1: Demo Patient Session Data

    func testDemoPatient_CanFetchSessionData() throws {
        // Arrange: Simulate session exercises response from database
        let json = SessionExerciseFixtures.exercisesJSON

        // Act: Decode the response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct SessionExerciseResponse: Codable {
            let id: String
            let sessionId: String
            let exerciseTemplateId: String
            let prescribedSets: Int
            let prescribedReps: String
            let prescribedLoad: Double?
            let loadUnit: String?
            let restPeriodSeconds: Int?
            let notes: String?
            let sequence: Int?
            let targetSets: Int?
        }

        let exercises = try decoder.decode([SessionExerciseResponse].self, from: json.jsonData)

        // Assert: Verify data integrity
        XCTAssertEqual(exercises.count, SessionExerciseFixtures.expectedExerciseCount)
        XCTAssertEqual(exercises.first?.prescribedSets, SessionExerciseFixtures.expectedFirstExerciseSets)
        XCTAssertEqual(exercises.first?.sessionId, DemoAccountIDs.sessionId.uuidString.lowercased())
    }

    // MARK: - Test 2: Session Exercises Decode with target_sets

    func testDemoPatient_SessionExercisesDecodeWithTargetSets() throws {
        // Arrange: JSON with target_sets field
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000901",
            "session_id": "00000000-0000-0000-0000-000000000010",
            "exercise_template_id": "00000000-0000-0000-0000-000000000801",
            "prescribed_sets": 3,
            "prescribed_reps": "10-12",
            "prescribed_load": 25.0,
            "load_unit": "lbs",
            "rest_period_seconds": 60,
            "notes": "Focus on controlled eccentric",
            "sequence": 1,
            "target_sets": 3
        }
        """

        // Act: Decode with target_sets handling
        struct SessionExerciseWithTargetSets: Codable {
            let id: String
            let sessionId: String
            let exerciseTemplateId: String
            let prescribedSets: Int
            let prescribedReps: String
            let prescribedLoad: Double?
            let loadUnit: String?
            let restPeriodSeconds: Int?
            let notes: String?
            let sequence: Int?
            let targetSets: Int?

            enum CodingKeys: String, CodingKey {
                case id
                case sessionId = "session_id"
                case exerciseTemplateId = "exercise_template_id"
                case prescribedSets = "prescribed_sets"
                case prescribedReps = "prescribed_reps"
                case prescribedLoad = "prescribed_load"
                case loadUnit = "load_unit"
                case restPeriodSeconds = "rest_period_seconds"
                case notes
                case sequence
                case targetSets = "target_sets"
            }
        }

        let decoder = JSONDecoder()
        let exercise = try decoder.decode(SessionExerciseWithTargetSets.self, from: json.data(using: .utf8)!)

        // Assert: target_sets decodes correctly
        XCTAssertEqual(exercise.targetSets, 3)
        XCTAssertEqual(exercise.prescribedSets, exercise.targetSets)
        XCTAssertEqual(exercise.prescribedReps, "10-12")
        XCTAssertEqual(exercise.prescribedLoad, 25.0)
    }

    // MARK: - Test 3: Demo Patient Streak Records

    func testDemoPatient_StreakRecordsLoadCorrectly() throws {
        // Arrange
        let json = StreakRecordFixtures.streakRecordsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([StreakRecord].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(records.count, 3)

        // Verify workout streak
        let workoutStreak = records.first { $0.streakType == .workout }
        XCTAssertNotNil(workoutStreak)
        XCTAssertEqual(workoutStreak?.currentStreak, StreakRecordFixtures.expectedWorkoutStreak)
        XCTAssertEqual(workoutStreak?.patientId, DemoAccountIDs.patientId)

        // Verify arm care streak
        let armCareStreak = records.first { $0.streakType == .armCare }
        XCTAssertNotNil(armCareStreak)
        XCTAssertEqual(armCareStreak?.currentStreak, StreakRecordFixtures.expectedArmCareStreak)

        // Verify combined streak exists
        let combinedStreak = records.first { $0.streakType == .combined }
        XCTAssertNotNil(combinedStreak)
    }

    // MARK: - Test 4: Demo Patient Readiness Check-ins

    func testDemoPatient_ReadinessCheckInsLoadCorrectly() throws {
        // Arrange
        let json = DailyReadinessFixtures.readinessCheckInsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([DailyReadiness].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(checkIns.count, 3)

        // Verify most recent entry
        let latestCheckIn = checkIns.first
        XCTAssertNotNil(latestCheckIn)
        XCTAssertEqual(latestCheckIn?.readinessScore, DailyReadinessFixtures.expectedLatestReadinessScore)
        XCTAssertEqual(latestCheckIn?.readinessBand, DailyReadinessFixtures.expectedLatestReadinessBand)
        XCTAssertEqual(latestCheckIn?.patientId, DemoAccountIDs.patientId)

        // Verify sleep hours decoding
        XCTAssertEqual(latestCheckIn?.sleepHours, 7.5)

        // Verify second entry has different band (yellow: 60-79)
        let secondCheckIn = checkIns[1]
        XCTAssertEqual(secondCheckIn.readinessBand, ReadinessBand.yellow)
    }

    // MARK: - Test 5: Demo Patient Arm Care Assessments

    func testDemoPatient_ArmCareAssessmentsLoadCorrectly() throws {
        // Arrange
        let json = ArmCareAssessmentFixtures.assessmentsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let assessments = try decoder.decode([ArmCareAssessment].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(assessments.count, 2)

        // Verify most recent assessment
        let latestAssessment = assessments.first
        XCTAssertNotNil(latestAssessment)
        XCTAssertEqual(latestAssessment?.trafficLight, ArmCareAssessmentFixtures.expectedLatestTrafficLight)
        XCTAssertEqual(latestAssessment?.overallScore ?? 0, ArmCareAssessmentFixtures.expectedLatestOverallScore, accuracy: 0.01)
        XCTAssertEqual(latestAssessment?.patientId, DemoAccountIDs.patientId)

        // Verify shoulder and elbow scores
        XCTAssertEqual(latestAssessment?.shoulderScore ?? 0, 8.67, accuracy: 0.01)
        XCTAssertEqual(latestAssessment?.elbowScore ?? 0, 9.67, accuracy: 0.01)

        // Verify second assessment has yellow traffic light
        let secondAssessment = assessments[1]
        XCTAssertEqual(secondAssessment.trafficLight, ArmCareTrafficLight.yellow)
        XCTAssertNotNil(secondAssessment.painLocations)
        XCTAssertEqual(secondAssessment.painLocations?.count, 1)
    }

    // MARK: - Test 6: Demo Patient Goals

    func testDemoPatient_GoalsLoadCorrectly() throws {
        // Arrange
        let json = PatientGoalFixtures.goalsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let goals = try decoder.decode([PatientGoal].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(goals.count, PatientGoalFixtures.expectedActiveGoalCount)

        // Verify all goals belong to demo patient
        for goal in goals {
            XCTAssertEqual(goal.patientId, DemoAccountIDs.patientId)
            XCTAssertEqual(goal.status, .active)
        }

        // Verify rehabilitation goal progress
        let rehabGoal = goals.first { $0.category == .rehabilitation }
        XCTAssertNotNil(rehabGoal)
        XCTAssertEqual(rehabGoal?.title, "Return to Full Throwing")
        XCTAssertEqual(rehabGoal?.progress ?? 0, PatientGoalFixtures.expectedThrowingProgress, accuracy: 0.01)

        // Verify mobility goal
        let mobilityGoal = goals.first { $0.category == .mobility }
        XCTAssertNotNil(mobilityGoal)
        XCTAssertEqual(mobilityGoal?.unit, "degrees")

        // Verify pain reduction goal
        let painGoal = goals.first { $0.category == .painReduction }
        XCTAssertNotNil(painGoal)
        XCTAssertEqual(painGoal?.targetValue, 0) // Goal is zero pain
    }
}

// MARK: - Demo Therapist Integration Tests

final class DemoTherapistIntegrationTests: XCTestCase {

    // MARK: - Test 7: Demo Therapist Patient List

    func testDemoTherapist_CanFetchPatientList() throws {
        // Arrange
        let json = PatientListFixtures.patientsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let patients = try decoder.decode([Patient].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(patients.count, PatientListFixtures.expectedPatientCount)

        // Verify demo patient is in list
        let demoPatient = patients.first { $0.id == DemoAccountIDs.patientId }
        XCTAssertNotNil(demoPatient)
        XCTAssertEqual(demoPatient?.firstName, "John")
        XCTAssertEqual(demoPatient?.lastName, "Brebbia")
        XCTAssertEqual(demoPatient?.sport, "Baseball")
        XCTAssertEqual(demoPatient?.position, "Pitcher")
        XCTAssertEqual(demoPatient?.injuryType, "Tommy John Recovery")
    }

    // MARK: - Test 8: Demo Therapist Patient Details

    func testDemoTherapist_CanViewPatientDetails() throws {
        // Arrange
        let json = PatientListFixtures.patientsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let patients = try decoder.decode([Patient].self, from: json.jsonData)

        let demoPatient = patients.first { $0.id == DemoAccountIDs.patientId }

        // Assert
        XCTAssertNotNil(demoPatient)
        XCTAssertEqual(demoPatient?.therapistId, DemoAccountIDs.therapistId)
        XCTAssertEqual(demoPatient?.adherencePercentage, PatientListFixtures.expectedDemoPatientAdherence)
        XCTAssertEqual(demoPatient?.targetLevel, "MLB")
        XCTAssertEqual(demoPatient?.flagCount, 0)
        XCTAssertFalse(demoPatient?.hasHighSeverityFlags ?? true)

        // Verify computed properties
        XCTAssertEqual(demoPatient?.fullName, "John Brebbia")
        XCTAssertEqual(demoPatient?.initials, "JB")
    }

    // MARK: - Test 9: Demo Therapist Clinical Assessments

    func testDemoTherapist_ClinicalAssessmentsDecodeCorrectly() throws {
        // Arrange
        let json = ClinicalAssessmentFixtures.assessmentsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let assessments = try decoder.decode([ClinicalAssessment].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(assessments.count, 2)

        // Verify most recent assessment
        let latestAssessment = assessments.first
        XCTAssertNotNil(latestAssessment)
        XCTAssertEqual(latestAssessment?.assessmentType, ClinicalAssessmentFixtures.expectedLatestAssessmentType)
        XCTAssertEqual(latestAssessment?.status, ClinicalAssessmentFixtures.expectedLatestStatus)
        XCTAssertEqual(latestAssessment?.patientId, DemoAccountIDs.patientId)
        XCTAssertEqual(latestAssessment?.therapistId, DemoAccountIDs.therapistId)

        // Verify ROM measurements decode
        XCTAssertNotNil(latestAssessment?.romMeasurements)
        XCTAssertEqual(latestAssessment?.romMeasurements?.count, 1)
        let romMeasurement = latestAssessment?.romMeasurements?.first
        XCTAssertEqual(romMeasurement?.joint, "Shoulder")
        XCTAssertEqual(romMeasurement?.movement, "External Rotation")
        XCTAssertEqual(romMeasurement?.degrees, 105)

        // Verify functional tests decode
        XCTAssertNotNil(latestAssessment?.functionalTests)
        XCTAssertEqual(latestAssessment?.functionalTests?.count, 1)
        let functionalTest = latestAssessment?.functionalTests?.first
        XCTAssertEqual(functionalTest?.testName, "UCL Stress Test")
        XCTAssertEqual(functionalTest?.result, "Negative")

        // Verify pain scores
        XCTAssertEqual(latestAssessment?.painAtRest, 0)
        XCTAssertEqual(latestAssessment?.painWithActivity, 2)
        XCTAssertEqual(latestAssessment?.painWorst, 4)

        // Verify intake assessment
        let intakeAssessment = assessments.first { $0.assessmentType == .intake }
        XCTAssertNotNil(intakeAssessment)
        XCTAssertEqual(intakeAssessment?.status, .signed)
        XCTAssertNotNil(intakeAssessment?.signedAt)
    }

    // MARK: - Test 10: Demo Therapist SOAP Notes

    func testDemoTherapist_SOAPNotesDecodeCorrectly() throws {
        // Arrange
        let json = SOAPNoteFixtures.notesJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let notes = try decoder.decode([SOAPNote].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(notes.count, 2)

        // Verify most recent note
        let latestNote = notes.first
        XCTAssertNotNil(latestNote)
        XCTAssertEqual(latestNote?.functionalStatus, SOAPNoteFixtures.expectedLatestFunctionalStatus)
        XCTAssertEqual(latestNote?.painLevel, SOAPNoteFixtures.expectedLatestPainLevel)
        XCTAssertEqual(latestNote?.patientId, DemoAccountIDs.patientId)
        XCTAssertEqual(latestNote?.therapistId, DemoAccountIDs.therapistId)

        // Verify SOAP components are populated
        XCTAssertNotNil(latestNote?.subjective)
        XCTAssertNotNil(latestNote?.objective)
        XCTAssertNotNil(latestNote?.assessment)
        XCTAssertNotNil(latestNote?.plan)
        XCTAssertTrue(latestNote?.subjective?.contains("feeling strong") ?? false)

        // Verify vitals decode
        XCTAssertNotNil(latestNote?.vitals)
        XCTAssertEqual(latestNote?.vitals?.bloodPressure, "118/76")
        XCTAssertEqual(latestNote?.vitals?.heartRate, 68)

        // Verify CPT codes
        XCTAssertEqual(latestNote?.cptCodes?.count, 3)
        XCTAssertTrue(latestNote?.cptCodes?.contains("97110") ?? false)

        // Verify time spent
        XCTAssertEqual(latestNote?.timeSpentMinutes, 60)
        XCTAssertEqual(latestNote?.formattedTimeSpent, "1h")

        // Verify second note is signed
        let signedNote = notes.first { $0.status == .signed }
        XCTAssertNotNil(signedNote)
        XCTAssertNotNil(signedNote?.signedAt)
        XCTAssertEqual(signedNote?.signedBy, "Dr. Sarah Mitchell, PT, DPT")

        // Verify completeness calculation
        XCTAssertEqual(latestNote?.completenessPercentage, 100.0)
    }

    // MARK: - Test 11: Demo Therapist Outcome Measures

    func testDemoTherapist_OutcomeMeasuresLoadCorrectly() throws {
        // Arrange
        let json = OutcomeMeasureFixtures.measuresJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let measures = try decoder.decode([OutcomeMeasure].self, from: json.jsonData)

        // Assert
        XCTAssertEqual(measures.count, 2)

        // Verify most recent measure
        let latestMeasure = measures.first
        XCTAssertNotNil(latestMeasure)
        XCTAssertEqual(latestMeasure?.measureType, OutcomeMeasureFixtures.expectedLatestMeasureType)
        XCTAssertEqual(latestMeasure?.meetsMcid, OutcomeMeasureFixtures.expectedMeetsMCID)
        XCTAssertEqual(latestMeasure?.changeFromPrevious, OutcomeMeasureFixtures.expectedChangeFromPrevious)
        XCTAssertEqual(latestMeasure?.patientId, DemoAccountIDs.patientId)
        XCTAssertEqual(latestMeasure?.therapistId, DemoAccountIDs.therapistId)

        // Verify responses decode
        XCTAssertEqual(latestMeasure?.responses.count, 30) // DASH has 30 questions

        // Verify scores
        XCTAssertEqual(latestMeasure?.rawScore, 12.5)
        XCTAssertEqual(latestMeasure?.normalizedScore, 12.5)
        XCTAssertEqual(latestMeasure?.previousScore, 28.0)

        // Verify interpretation
        XCTAssertEqual(latestMeasure?.interpretation, "Minimal disability")

        // Verify clinical assessment link
        XCTAssertNotNil(latestMeasure?.clinicalAssessmentId)

        // Verify progress status computation
        XCTAssertTrue(latestMeasure?.showsImprovement ?? false)
        XCTAssertFalse(latestMeasure?.showsDecline ?? true)
        XCTAssertEqual(latestMeasure?.progressStatus, .improving)

        // Verify baseline measure
        let baselineMeasure = measures.first { $0.previousScore == nil }
        XCTAssertNotNil(baselineMeasure)
        XCTAssertNil(baselineMeasure?.changeFromPrevious)
        XCTAssertNil(baselineMeasure?.meetsMcid)
    }
}

// MARK: - Demo Mode Data Integrity Tests

final class DemoModeDataIntegrityTests: XCTestCase {

    // MARK: - Cross-Reference Tests

    func testDemoData_PatientTherapistRelationship() throws {
        // Arrange
        let patientsJson = PatientListFixtures.patientsJSON
        let clinicalJson = ClinicalAssessmentFixtures.assessmentsJSON

        // Act
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let patients = try decoder.decode([Patient].self, from: patientsJson.jsonData)
        let assessments = try decoder.decode([ClinicalAssessment].self, from: clinicalJson.jsonData)

        // Assert: Patient therapist_id matches assessment therapist_id
        let demoPatient = patients.first { $0.id == DemoAccountIDs.patientId }
        let assessment = assessments.first

        XCTAssertEqual(demoPatient?.therapistId, assessment?.therapistId)
        XCTAssertEqual(demoPatient?.therapistId, DemoAccountIDs.therapistId)
    }

    func testDemoData_AllRecordsBelongToDemoPatient() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Act & Assert: Verify all fixture data belongs to demo patient
        let streaks = try decoder.decode([StreakRecord].self, from: StreakRecordFixtures.streakRecordsJSON.jsonData)
        for streak in streaks {
            XCTAssertEqual(streak.patientId, DemoAccountIDs.patientId, "Streak record should belong to demo patient")
        }

        let readiness = try decoder.decode([DailyReadiness].self, from: DailyReadinessFixtures.readinessCheckInsJSON.jsonData)
        for entry in readiness {
            XCTAssertEqual(entry.patientId, DemoAccountIDs.patientId, "Readiness entry should belong to demo patient")
        }

        let armCare = try decoder.decode([ArmCareAssessment].self, from: ArmCareAssessmentFixtures.assessmentsJSON.jsonData)
        for assessment in armCare {
            XCTAssertEqual(assessment.patientId, DemoAccountIDs.patientId, "Arm care assessment should belong to demo patient")
        }

        let goals = try decoder.decode([PatientGoal].self, from: PatientGoalFixtures.goalsJSON.jsonData)
        for goal in goals {
            XCTAssertEqual(goal.patientId, DemoAccountIDs.patientId, "Goal should belong to demo patient")
        }
    }

    func testDemoData_AllTherapistRecordsCreatedByDemoTherapist() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Act & Assert
        let clinicalAssessments = try decoder.decode([ClinicalAssessment].self, from: ClinicalAssessmentFixtures.assessmentsJSON.jsonData)
        for assessment in clinicalAssessments {
            XCTAssertEqual(assessment.therapistId, DemoAccountIDs.therapistId, "Clinical assessment should be by demo therapist")
        }

        let soapNotes = try decoder.decode([SOAPNote].self, from: SOAPNoteFixtures.notesJSON.jsonData)
        for note in soapNotes {
            XCTAssertEqual(note.therapistId, DemoAccountIDs.therapistId, "SOAP note should be by demo therapist")
        }

        let outcomeMeasures = try decoder.decode([OutcomeMeasure].self, from: OutcomeMeasureFixtures.measuresJSON.jsonData)
        for measure in outcomeMeasures {
            XCTAssertEqual(measure.therapistId, DemoAccountIDs.therapistId, "Outcome measure should be by demo therapist")
        }
    }

    // MARK: - Streak Badge Tests

    func testDemoPatient_StreakBadgeCalculation() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([StreakRecord].self, from: StreakRecordFixtures.streakRecordsJSON.jsonData)

        // Act
        let workoutStreak = records.first { $0.streakType == .workout }

        // badgeLevel is based on longestStreak, not currentStreak
        // longestStreak of 21 days = "Dedicated" badge (14-29 days)
        XCTAssertEqual(workoutStreak?.badgeLevel, StreakBadge.dedicated)
        XCTAssertEqual(workoutStreak?.badgeLevel.displayName, "Dedicated")

        // Verify the badge calculation directly
        let longestStreakBadge = StreakBadge.badge(for: workoutStreak?.longestStreak ?? 0)
        XCTAssertEqual(longestStreakBadge, StreakBadge.dedicated)
    }

    // MARK: - Readiness Band Tests

    func testDemoPatient_ReadinessBandCalculation() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([DailyReadiness].self, from: DailyReadinessFixtures.readinessCheckInsJSON.jsonData)

        // Act & Assert
        // Score 82.5 -> Green (80+)
        XCTAssertEqual(checkIns[0].readinessBand, .green)

        // Score 62.0 -> Yellow (60-79)
        XCTAssertEqual(checkIns[1].readinessBand, .yellow)

        // Score 91.0 -> Green (80+)
        XCTAssertEqual(checkIns[2].readinessBand, .green)
    }

    // MARK: - Arm Care Traffic Light Tests

    func testDemoPatient_ArmCareTrafficLightCalculation() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let assessments = try decoder.decode([ArmCareAssessment].self, from: ArmCareAssessmentFixtures.assessmentsJSON.jsonData)

        // Act & Assert
        // Score 9.17 -> Green (8-10)
        XCTAssertEqual(assessments[0].trafficLight, .green)
        XCTAssertEqual(assessments[0].trafficLight.throwingVolumeMultiplier, 1.0)
        XCTAssertFalse(assessments[0].trafficLight.requiresExtraArmCare)

        // Score 6.50 -> Yellow (5-7.99)
        XCTAssertEqual(assessments[1].trafficLight, .yellow)
        XCTAssertEqual(assessments[1].trafficLight.throwingVolumeMultiplier, 0.5)
        XCTAssertTrue(assessments[1].trafficLight.requiresExtraArmCare)
    }

    // MARK: - Goal Progress Tests

    func testDemoPatient_GoalProgressCalculation() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let goals = try decoder.decode([PatientGoal].self, from: PatientGoalFixtures.goalsJSON.jsonData)

        // Act
        let rehabGoal = goals.first { $0.category == .rehabilitation }
        let mobilityGoal = goals.first { $0.category == .mobility }

        // Assert
        // Rehab goal: 75/100 = 75%
        XCTAssertEqual(rehabGoal?.progress ?? 0, 0.75, accuracy: 0.01)
        XCTAssertEqual(rehabGoal?.progressPercentageText, "75%")
        XCTAssertFalse(rehabGoal?.isCompleted ?? true)

        // Mobility goal: 105/115 = 91.3%
        XCTAssertEqual(mobilityGoal?.progress ?? 0, 105.0 / 115.0, accuracy: 0.01)
        XCTAssertFalse(mobilityGoal?.isCompleted ?? true)
    }

    // MARK: - Outcome Measure MCID Tests

    func testDemoPatient_OutcomeMeasureMCIDCalculation() throws {
        // Arrange
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let measures = try decoder.decode([OutcomeMeasure].self, from: OutcomeMeasureFixtures.measuresJSON.jsonData)

        // Act
        let latestMeasure = measures.first

        // Assert
        // DASH MCID threshold is 10.8
        // Change of -15.5 exceeds threshold (lower is better for DASH)
        XCTAssertTrue(latestMeasure?.meetsMcid ?? false)
        XCTAssertTrue(latestMeasure?.showsImprovement ?? false)

        // Verify MCID threshold for DASH
        XCTAssertEqual(OutcomeMeasureType.DASH.mcidThreshold, 10.8)
        XCTAssertFalse(OutcomeMeasureType.DASH.higherIsBetter)
    }
}

// MARK: - Demo Mode Edge Case Tests

final class DemoModeEdgeCaseTests: XCTestCase {

    func testDemoData_HandlesNullOptionalFields() throws {
        // Test that optional fields decode correctly when null
        let jsonWithNulls = """
        {
            "id": "00000000-0000-0000-0000-000000000999",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-07",
            "sleep_hours": null,
            "soreness_level": null,
            "energy_level": 7,
            "stress_level": null,
            "readiness_score": null,
            "notes": null,
            "created_at": "2026-02-07T08:00:00Z",
            "updated_at": "2026-02-07T08:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let readiness = try decoder.decode(DailyReadiness.self, from: jsonWithNulls.data(using: .utf8)!)

        XCTAssertNil(readiness.sleepHours)
        XCTAssertNil(readiness.sorenessLevel)
        XCTAssertEqual(readiness.energyLevel, 7)
        XCTAssertNil(readiness.stressLevel)
        XCTAssertNil(readiness.readinessScore)
        XCTAssertNil(readiness.notes)
    }

    func testDemoData_HandlesNumericStringsFromPostgreSQL() throws {
        // PostgreSQL NUMERIC types may come as strings
        let jsonWithStringNumbers = """
        {
            "id": "00000000-0000-0000-0000-000000000999",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-07",
            "shoulder_pain_score": 8,
            "shoulder_stiffness_score": 7,
            "shoulder_strength_score": 9,
            "elbow_pain_score": 9,
            "elbow_tightness_score": 8,
            "valgus_stress_score": 9,
            "shoulder_score": "8.00",
            "elbow_score": "8.67",
            "overall_score": "8.33",
            "traffic_light": "green",
            "pain_locations": null,
            "notes": null,
            "created_at": "2026-02-07T07:00:00Z",
            "updated_at": "2026-02-07T07:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let assessment = try decoder.decode(ArmCareAssessment.self, from: jsonWithStringNumbers.data(using: .utf8)!)

        XCTAssertEqual(assessment.shoulderScore, 8.00, accuracy: 0.01)
        XCTAssertEqual(assessment.elbowScore, 8.67, accuracy: 0.01)
        XCTAssertEqual(assessment.overallScore, 8.33, accuracy: 0.01)
    }

    func testDemoData_HandlesDateOnlyFormat() throws {
        // PostgreSQL DATE columns return "YYYY-MM-DD" format
        let jsonWithDateOnly = """
        {
            "id": "00000000-0000-0000-0000-000000000999",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "streak_type": "workout",
            "current_streak": 5,
            "longest_streak": 10,
            "last_activity_date": "2026-02-07",
            "streak_start_date": "2026-02-02",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-02-07T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let streak = try decoder.decode(StreakRecord.self, from: jsonWithDateOnly.data(using: .utf8)!)

        XCTAssertNotNil(streak.lastActivityDate)
        XCTAssertNotNil(streak.streakStartDate)

        // Verify the date was parsed correctly
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: streak.lastActivityDate!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 7)
    }
}
