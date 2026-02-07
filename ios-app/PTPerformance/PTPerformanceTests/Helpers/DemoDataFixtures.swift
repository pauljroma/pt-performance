//
//  DemoDataFixtures.swift
//  PTPerformanceTests
//
//  Fixture data for demo mode integration tests.
//  Matches the migration seed data for demo patient and therapist accounts.
//

import Foundation
@testable import PTPerformance

// MARK: - Demo Account IDs

/// Well-known demo account identifiers from database migrations
enum DemoAccountIDs {
    /// Demo patient ID: John Brebbia
    static let patientId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// Demo therapist ID
    static let therapistId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// Demo session ID (for exercise/session tests)
    static let sessionId = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    /// Demo program ID
    static let programId = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
}

// MARK: - Streak Record Fixtures

enum StreakRecordFixtures {

    /// JSON response for demo patient streak records
    static let streakRecordsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000101",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "streak_type": "workout",
            "current_streak": 12,
            "longest_streak": 21,
            "last_activity_date": "2026-02-06",
            "streak_start_date": "2026-01-25",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-02-06T00:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000102",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "streak_type": "arm_care",
            "current_streak": 8,
            "longest_streak": 15,
            "last_activity_date": "2026-02-06",
            "streak_start_date": "2026-01-29",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-02-06T00:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000103",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "streak_type": "combined",
            "current_streak": 8,
            "longest_streak": 15,
            "last_activity_date": "2026-02-06",
            "streak_start_date": "2026-01-29",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-02-06T00:00:00Z"
        }
    ]
    """

    /// Expected workout streak current count
    static let expectedWorkoutStreak = 12

    /// Expected arm care streak current count
    static let expectedArmCareStreak = 8
}

// MARK: - Daily Readiness Fixtures

enum DailyReadinessFixtures {

    /// JSON response for demo patient daily readiness check-ins
    static let readinessCheckInsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000201",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-06",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 8,
            "stress_level": 4,
            "readiness_score": 82.5,
            "notes": "Feeling good after rest day",
            "created_at": "2026-02-06T08:00:00Z",
            "updated_at": "2026-02-06T08:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000202",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-05",
            "sleep_hours": 6.0,
            "soreness_level": 5,
            "energy_level": 6,
            "stress_level": 6,
            "readiness_score": 62.0,
            "notes": "Heavy throwing day yesterday",
            "created_at": "2026-02-05T08:00:00Z",
            "updated_at": "2026-02-05T08:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000203",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-04",
            "sleep_hours": 8.0,
            "soreness_level": 2,
            "energy_level": 9,
            "stress_level": 3,
            "readiness_score": 91.0,
            "notes": null,
            "created_at": "2026-02-04T08:00:00Z",
            "updated_at": "2026-02-04T08:00:00Z"
        }
    ]
    """

    /// Expected readiness score for most recent entry
    static let expectedLatestReadinessScore = 82.5

    /// Expected readiness band for most recent entry (green: 80+)
    static let expectedLatestReadinessBand = ReadinessBand.green
}

// MARK: - Arm Care Assessment Fixtures

enum ArmCareAssessmentFixtures {

    /// JSON response for demo patient arm care assessments
    static let assessmentsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000301",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-06",
            "shoulder_pain_score": 9,
            "shoulder_stiffness_score": 8,
            "shoulder_strength_score": 9,
            "elbow_pain_score": 10,
            "elbow_tightness_score": 9,
            "valgus_stress_score": 10,
            "shoulder_score": "8.67",
            "elbow_score": "9.67",
            "overall_score": "9.17",
            "traffic_light": "green",
            "pain_locations": null,
            "notes": "Arm feels great today",
            "created_at": "2026-02-06T07:00:00Z",
            "updated_at": "2026-02-06T07:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000302",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-02-05",
            "shoulder_pain_score": 7,
            "shoulder_stiffness_score": 6,
            "shoulder_strength_score": 7,
            "elbow_pain_score": 6,
            "elbow_tightness_score": 6,
            "valgus_stress_score": 7,
            "shoulder_score": "6.67",
            "elbow_score": "6.33",
            "overall_score": "6.50",
            "traffic_light": "yellow",
            "pain_locations": ["medial_elbow"],
            "notes": "Some tightness after long toss",
            "created_at": "2026-02-05T07:00:00Z",
            "updated_at": "2026-02-05T07:00:00Z"
        }
    ]
    """

    /// Expected traffic light for most recent assessment
    static let expectedLatestTrafficLight = ArmCareTrafficLight.green

    /// Expected overall score for most recent assessment
    static let expectedLatestOverallScore = 9.17
}

// MARK: - Patient Goal Fixtures

enum PatientGoalFixtures {

    /// JSON response for demo patient goals
    static let goalsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000401",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "title": "Return to Full Throwing",
            "description": "Complete return-to-throw protocol and achieve full velocity",
            "category": "rehabilitation",
            "target_value": 100,
            "current_value": 75,
            "unit": "percent",
            "target_date": "2026-04-01T00:00:00Z",
            "status": "active",
            "created_at": "2026-01-15T00:00:00Z",
            "updated_at": "2026-02-06T00:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000402",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "title": "Increase Shoulder External Rotation",
            "description": "Improve ER by 15 degrees to match pre-surgery range",
            "category": "mobility",
            "target_value": 115,
            "current_value": 105,
            "unit": "degrees",
            "target_date": "2026-03-15T00:00:00Z",
            "status": "active",
            "created_at": "2026-01-15T00:00:00Z",
            "updated_at": "2026-02-01T00:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000403",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "title": "Reduce Elbow Pain",
            "description": "Achieve pain-free throwing at all intensities",
            "category": "pain_reduction",
            "target_value": 0,
            "current_value": 2,
            "unit": "pain_scale",
            "target_date": "2026-03-01T00:00:00Z",
            "status": "active",
            "created_at": "2026-01-15T00:00:00Z",
            "updated_at": "2026-02-05T00:00:00Z"
        }
    ]
    """

    /// Expected number of active goals
    static let expectedActiveGoalCount = 3

    /// Expected progress for "Return to Full Throwing" goal (75/100)
    static let expectedThrowingProgress = 0.75
}

// MARK: - Clinical Assessment Fixtures

enum ClinicalAssessmentFixtures {

    /// JSON response for clinical assessments (therapist view)
    static let assessmentsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000501",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "assessment_type": "progress",
            "assessment_date": "2026-02-06T00:00:00Z",
            "rom_measurements": [
                {
                    "id": "00000000-0000-0000-0000-000000000601",
                    "joint": "Shoulder",
                    "movement": "External Rotation",
                    "degrees": 105,
                    "normal_range_min": 90,
                    "normal_range_max": 120,
                    "side": "right",
                    "pain_with_movement": false
                }
            ],
            "functional_tests": [
                {
                    "id": "00000000-0000-0000-0000-000000000602",
                    "test_name": "UCL Stress Test",
                    "result": "Negative",
                    "interpretation": "No laxity detected"
                }
            ],
            "pain_at_rest": 0,
            "pain_with_activity": 2,
            "pain_worst": 4,
            "pain_locations": ["Medial elbow"],
            "chief_complaint": "Mild discomfort with high-intensity throws",
            "history_of_present_illness": "Post-UCL reconstruction, now 8 months out. Progressing through return-to-throw protocol.",
            "past_medical_history": "UCL reconstruction August 2025",
            "functional_goals": ["Return to competitive pitching", "Achieve 90+ mph velocity"],
            "objective_findings": "Shoulder ROM WNL, elbow stable, grip strength 95% of contralateral",
            "assessment_summary": "Progressing well in rehab. Ready to advance to long-toss phase.",
            "treatment_plan": "Continue arm care program, advance throwing distance to 150ft",
            "status": "complete",
            "signed_at": "2026-02-06T15:00:00Z",
            "created_at": "2026-02-06T14:00:00Z",
            "updated_at": "2026-02-06T15:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000502",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "assessment_type": "intake",
            "assessment_date": "2026-01-15T00:00:00Z",
            "rom_measurements": null,
            "functional_tests": null,
            "pain_at_rest": 2,
            "pain_with_activity": 5,
            "pain_worst": 7,
            "pain_locations": ["Medial elbow", "Posterior shoulder"],
            "chief_complaint": "Post-UCL reconstruction rehabilitation",
            "history_of_present_illness": "5 months post-UCL reconstruction. Referred for return-to-throw protocol.",
            "past_medical_history": "UCL reconstruction August 2025, no other significant history",
            "functional_goals": ["Return to MLB pitching", "Full velocity by spring training"],
            "objective_findings": "Limited shoulder ER, reduced grip strength, positive moving valgus stress",
            "assessment_summary": "5 months post-op UCL. Ready to begin return-to-throw protocol.",
            "treatment_plan": "Begin phase 1 throwing program, continue arm strengthening",
            "status": "signed",
            "signed_at": "2026-01-15T16:00:00Z",
            "created_at": "2026-01-15T14:00:00Z",
            "updated_at": "2026-01-15T16:00:00Z"
        }
    ]
    """

    /// Expected assessment type for most recent assessment
    static let expectedLatestAssessmentType = AssessmentType.progress

    /// Expected status for most recent assessment
    static let expectedLatestStatus = AssessmentStatus.complete
}

// MARK: - SOAP Note Fixtures

enum SOAPNoteFixtures {

    /// JSON response for SOAP notes (therapist view)
    static let notesJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000701",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "session_id": "00000000-0000-0000-0000-000000000010",
            "note_date": "2026-02-06T00:00:00Z",
            "subjective": "Patient reports feeling strong today. Arm felt good during warm-up throws. No pain with band work.",
            "objective": "Completed 45 throws at 120ft. Max effort 85%. No pain during session. Shoulder ER 105 degrees. UCL stress test negative.",
            "assessment": "Patient progressing well. Ready to advance distance. Arm care compliance excellent.",
            "plan": "Increase throwing distance to 150ft next session. Continue current arm care routine. Schedule follow-up in 1 week.",
            "vitals": {
                "blood_pressure": "118/76",
                "heart_rate": 68
            },
            "pain_level": 1,
            "functional_status": "improving",
            "time_spent_minutes": 60,
            "cpt_codes": ["97110", "97530", "97140"],
            "status": "complete",
            "signed_at": null,
            "signed_by": null,
            "parent_note_id": null,
            "created_at": "2026-02-06T15:00:00Z",
            "updated_at": "2026-02-06T15:30:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000702",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "session_id": null,
            "note_date": "2026-02-03T00:00:00Z",
            "subjective": "Reports mild soreness in posterior shoulder after yesterday's session. Sleep was poor (5 hours).",
            "objective": "Shoulder ROM maintained. Posterior capsule tightness noted. Completed modified arm care routine.",
            "assessment": "Mild delayed onset muscle soreness. Expected with increased throwing volume.",
            "plan": "Rest day tomorrow. Resume throwing protocol on 2/5. Add sleeper stretch to home program.",
            "vitals": null,
            "pain_level": 3,
            "functional_status": "stable",
            "time_spent_minutes": 45,
            "cpt_codes": ["97110", "97140"],
            "status": "signed",
            "signed_at": "2026-02-03T16:00:00Z",
            "signed_by": "Dr. Sarah Mitchell, PT, DPT",
            "parent_note_id": null,
            "created_at": "2026-02-03T14:00:00Z",
            "updated_at": "2026-02-03T16:00:00Z"
        }
    ]
    """

    /// Expected functional status for most recent note
    static let expectedLatestFunctionalStatus = FunctionalStatus.improving

    /// Expected pain level for most recent note
    static let expectedLatestPainLevel = 1
}

// MARK: - Outcome Measure Fixtures

enum OutcomeMeasureFixtures {

    /// JSON response for outcome measures (therapist view)
    static let measuresJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000801",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "clinical_assessment_id": "00000000-0000-0000-0000-000000000501",
            "measure_type": "DASH",
            "assessment_date": "2026-02-06T00:00:00Z",
            "responses": {
                "q1": 1, "q2": 1, "q3": 2, "q4": 1, "q5": 1,
                "q6": 1, "q7": 2, "q8": 1, "q9": 1, "q10": 1,
                "q11": 1, "q12": 1, "q13": 2, "q14": 1, "q15": 1,
                "q16": 1, "q17": 1, "q18": 1, "q19": 2, "q20": 1,
                "q21": 1, "q22": 1, "q23": 2, "q24": 1, "q25": 1,
                "q26": 1, "q27": 1, "q28": 2, "q29": 1, "q30": 1
            },
            "raw_score": 12.5,
            "normalized_score": 12.5,
            "interpretation": "Minimal disability",
            "previous_score": 28.0,
            "change_from_previous": -15.5,
            "meets_mcid": true,
            "notes": "Significant improvement since initial evaluation",
            "created_at": "2026-02-06T14:30:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000802",
            "patient_id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "clinical_assessment_id": "00000000-0000-0000-0000-000000000502",
            "measure_type": "DASH",
            "assessment_date": "2026-01-15T00:00:00Z",
            "responses": {
                "q1": 2, "q2": 2, "q3": 3, "q4": 2, "q5": 3,
                "q6": 2, "q7": 3, "q8": 2, "q9": 2, "q10": 3,
                "q11": 2, "q12": 2, "q13": 3, "q14": 2, "q15": 2,
                "q16": 2, "q17": 3, "q18": 2, "q19": 3, "q20": 2,
                "q21": 2, "q22": 2, "q23": 3, "q24": 2, "q25": 3,
                "q26": 2, "q27": 2, "q28": 3, "q29": 2, "q30": 2
            },
            "raw_score": 28.0,
            "normalized_score": 28.0,
            "interpretation": "Mild disability",
            "previous_score": null,
            "change_from_previous": null,
            "meets_mcid": null,
            "notes": "Baseline measurement at initial evaluation",
            "created_at": "2026-01-15T14:30:00Z"
        }
    ]
    """

    /// Expected measure type for most recent outcome measure
    static let expectedLatestMeasureType = OutcomeMeasureType.DASH

    /// Expected MCID achievement for most recent measure
    static let expectedMeetsMCID = true

    /// Expected change from previous
    static let expectedChangeFromPrevious = -15.5
}

// MARK: - Session Exercise Fixtures

enum SessionExerciseFixtures {

    /// JSON response for session exercises with target_sets field
    static let exercisesJSON = """
    [
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
        },
        {
            "id": "00000000-0000-0000-0000-000000000902",
            "session_id": "00000000-0000-0000-0000-000000000010",
            "exercise_template_id": "00000000-0000-0000-0000-000000000802",
            "prescribed_sets": 4,
            "prescribed_reps": "8",
            "prescribed_load": null,
            "load_unit": null,
            "rest_period_seconds": 90,
            "notes": "Bodyweight only",
            "sequence": 2,
            "target_sets": 4
        }
    ]
    """

    /// Expected number of exercises
    static let expectedExerciseCount = 2

    /// Expected prescribed sets for first exercise
    static let expectedFirstExerciseSets = 3
}

// MARK: - Patient List Fixtures

enum PatientListFixtures {

    /// JSON response for therapist patient list
    static let patientsJSON = """
    [
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "first_name": "John",
            "last_name": "Brebbia",
            "email": "demo-patient@ptperformance.app",
            "sport": "Baseball",
            "position": "Pitcher",
            "injury_type": "Tommy John Recovery",
            "target_level": "MLB",
            "profile_image_url": null,
            "created_at": "2026-01-01T00:00:00Z",
            "flag_count": 0,
            "high_severity_flag_count": 0,
            "adherence_percentage": 92.5,
            "last_session_date": "2026-02-06T00:00:00Z"
        },
        {
            "id": "00000000-0000-0000-0000-000000000003",
            "therapist_id": "00000000-0000-0000-0000-000000000002",
            "first_name": "Sarah",
            "last_name": "Johnson",
            "email": "sarah.johnson@example.com",
            "sport": "Basketball",
            "position": "Guard",
            "injury_type": "ACL Recovery",
            "target_level": "College",
            "profile_image_url": null,
            "created_at": "2026-01-10T00:00:00Z",
            "flag_count": 1,
            "high_severity_flag_count": 0,
            "adherence_percentage": 87.0,
            "last_session_date": "2026-02-05T00:00:00Z"
        }
    ]
    """

    /// Expected number of patients for demo therapist
    static let expectedPatientCount = 2

    /// Expected adherence percentage for demo patient
    static let expectedDemoPatientAdherence = 92.5
}

// MARK: - JSON Data Helpers

extension String {
    /// Convert JSON string to Data for decoding
    var jsonData: Data {
        data(using: .utf8)!
    }
}
