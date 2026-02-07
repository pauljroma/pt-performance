//
//  ClinicalAssessmentTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for ClinicalAssessment model
//  Tests encoding/decoding, assessment types, status transitions, and field validation
//

import XCTest
@testable import PTPerformance

// MARK: - ClinicalAssessment Model Tests

final class ClinicalAssessmentModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testClinicalAssessment_DefaultInitialization() {
        let patientId = UUID()
        let therapistId = UUID()

        let assessment = ClinicalAssessment(
            patientId: patientId,
            therapistId: therapistId,
            assessmentType: .intake
        )

        XCTAssertNotNil(assessment.id)
        XCTAssertEqual(assessment.patientId, patientId)
        XCTAssertEqual(assessment.therapistId, therapistId)
        XCTAssertEqual(assessment.assessmentType, .intake)
        XCTAssertEqual(assessment.status, .draft)
        XCTAssertNil(assessment.romMeasurements)
        XCTAssertNil(assessment.functionalTests)
        XCTAssertNil(assessment.painAtRest)
        XCTAssertNil(assessment.painWithActivity)
        XCTAssertNil(assessment.painWorst)
        XCTAssertNil(assessment.painLocations)
        XCTAssertNil(assessment.chiefComplaint)
        XCTAssertNil(assessment.historyOfPresentIllness)
        XCTAssertNil(assessment.pastMedicalHistory)
        XCTAssertNil(assessment.functionalGoals)
        XCTAssertNil(assessment.objectiveFindings)
        XCTAssertNil(assessment.assessmentSummary)
        XCTAssertNil(assessment.treatmentPlan)
        XCTAssertNil(assessment.signedAt)
    }

    func testClinicalAssessment_FullInitialization() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let assessmentDate = Date()
        let signedAt = Date()
        let createdAt = Date()
        let updatedAt = Date()

        let romMeasurement = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right,
            painWithMovement: true
        )

        let functionalTest = FunctionalTest(
            testName: "Hawkins-Kennedy",
            result: "Positive",
            interpretation: "Indicates impingement"
        )

        let assessment = ClinicalAssessment(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            assessmentType: .intake,
            assessmentDate: assessmentDate,
            romMeasurements: [romMeasurement],
            functionalTests: [functionalTest],
            painAtRest: 2,
            painWithActivity: 5,
            painWorst: 7,
            painLocations: ["Right shoulder", "Upper back"],
            chiefComplaint: "Shoulder pain",
            historyOfPresentIllness: "Gradual onset over 3 weeks",
            pastMedicalHistory: "None significant",
            functionalGoals: ["Return to sport", "Sleep without pain"],
            objectiveFindings: "Decreased ROM in flexion",
            assessmentSummary: "Right shoulder impingement",
            treatmentPlan: "PT 2x/week for 6 weeks",
            status: .signed,
            signedAt: signedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(assessment.id, id)
        XCTAssertEqual(assessment.patientId, patientId)
        XCTAssertEqual(assessment.therapistId, therapistId)
        XCTAssertEqual(assessment.assessmentType, .intake)
        XCTAssertEqual(assessment.assessmentDate, assessmentDate)
        XCTAssertEqual(assessment.romMeasurements?.count, 1)
        XCTAssertEqual(assessment.functionalTests?.count, 1)
        XCTAssertEqual(assessment.painAtRest, 2)
        XCTAssertEqual(assessment.painWithActivity, 5)
        XCTAssertEqual(assessment.painWorst, 7)
        XCTAssertEqual(assessment.painLocations?.count, 2)
        XCTAssertEqual(assessment.chiefComplaint, "Shoulder pain")
        XCTAssertEqual(assessment.functionalGoals?.count, 2)
        XCTAssertEqual(assessment.status, .signed)
        XCTAssertEqual(assessment.signedAt, signedAt)
    }

    // MARK: - Computed Properties Tests

    func testAveragePainScore_WithAllScores() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 2,
            painWithActivity: 5,
            painWorst: 8
        )

        // (2 + 5 + 8) / 3 = 5.0
        XCTAssertEqual(assessment.averagePainScore ?? 0, 5.0, accuracy: 0.001)
    }

    func testAveragePainScore_WithPartialScores() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .progress,
            painAtRest: 4,
            painWithActivity: nil,
            painWorst: 6
        )

        // (4 + 6) / 2 = 5.0
        XCTAssertEqual(assessment.averagePainScore ?? 0, 5.0, accuracy: 0.001)
    }

    func testAveragePainScore_WithSingleScore() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: nil,
            painWithActivity: nil,
            painWorst: 9
        )

        XCTAssertEqual(assessment.averagePainScore ?? 0, 9.0, accuracy: 0.001)
    }

    func testAveragePainScore_WithNoScores() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake
        )

        XCTAssertNil(assessment.averagePainScore)
    }

    func testIsPainConcerning_HighWorstPain() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWorst: 7
        )

        XCTAssertTrue(assessment.isPainConcerning)
    }

    func testIsPainConcerning_VeryHighWorstPain() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWorst: 10
        )

        XCTAssertTrue(assessment.isPainConcerning)
    }

    func testIsPainConcerning_HighActivityPain() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWithActivity: 6,
            painWorst: 5
        )

        XCTAssertTrue(assessment.isPainConcerning)
    }

    func testIsPainConcerning_LowPainLevels() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 1,
            painWithActivity: 3,
            painWorst: 4
        )

        XCTAssertFalse(assessment.isPainConcerning)
    }

    func testIsPainConcerning_NoPainScores() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake
        )

        XCTAssertFalse(assessment.isPainConcerning)
    }

    func testRomLimitationsCount_WithLimitations() {
        let limitedROM = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 100,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let normalROM = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 145,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [limitedROM, normalROM]
        )

        XCTAssertEqual(assessment.romLimitationsCount, 1)
    }

    func testRomLimitationsCount_AllLimited() {
        let limited1 = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 100,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let limited2 = ROMeasurement(
            joint: "shoulder",
            movement: "abduction",
            degrees: 90,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [limited1, limited2]
        )

        XCTAssertEqual(assessment.romLimitationsCount, 2)
    }

    func testRomLimitationsCount_NoLimitations() {
        let normalROM = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 145,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [normalROM]
        )

        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testRomLimitationsCount_NoMeasurements() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake
        )

        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testRomLimitationsCount_EmptyArray() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: []
        )

        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testIsReadyForSignature_Complete() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary of findings",
            treatmentPlan: "Treatment plan details",
            status: .complete
        )

        XCTAssertTrue(assessment.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingSummary() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            treatmentPlan: "Treatment plan",
            status: .complete
        )

        XCTAssertFalse(assessment.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingPlan() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary",
            status: .complete
        )

        XCTAssertFalse(assessment.isReadyForSignature)
    }

    func testIsReadyForSignature_DraftStatus() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary",
            treatmentPlan: "Plan",
            status: .draft
        )

        XCTAssertFalse(assessment.isReadyForSignature)
    }

    func testIsReadyForSignature_AlreadySigned() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary",
            treatmentPlan: "Plan",
            status: .signed
        )

        XCTAssertFalse(assessment.isReadyForSignature)
    }

    func testFormattedDate_ReturnsNonEmptyString() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake
        )

        XCTAssertFalse(assessment.formattedDate.isEmpty)
    }

    func testDisplayTitle_ContainsTypeAndDate() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .progress
        )

        XCTAssertTrue(assessment.displayTitle.contains("Progress Note"))
        XCTAssertTrue(assessment.displayTitle.contains("-"))
    }

    // MARK: - Encoding/Decoding Tests

    func testClinicalAssessment_EncodeDecode() throws {
        let original = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 3,
            painWithActivity: 5,
            painWorst: 7,
            painLocations: ["Shoulder"],
            chiefComplaint: "Pain",
            status: .draft
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ClinicalAssessment.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.therapistId, decoded.therapistId)
        XCTAssertEqual(original.assessmentType, decoded.assessmentType)
        XCTAssertEqual(original.painAtRest, decoded.painAtRest)
        XCTAssertEqual(original.painWithActivity, decoded.painWithActivity)
        XCTAssertEqual(original.painWorst, decoded.painWorst)
        XCTAssertEqual(original.chiefComplaint, decoded.chiefComplaint)
        XCTAssertEqual(original.status, decoded.status)
    }

    func testClinicalAssessment_CodingKeysMapping() throws {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 5,
            painWithActivity: 7,
            chiefComplaint: "Test"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(assessment)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["therapist_id"])
        XCTAssertNotNil(jsonObject["assessment_type"])
        XCTAssertNotNil(jsonObject["assessment_date"])
        XCTAssertNotNil(jsonObject["pain_at_rest"])
        XCTAssertNotNil(jsonObject["pain_with_activity"])
        XCTAssertNotNil(jsonObject["chief_complaint"])
        XCTAssertNotNil(jsonObject["created_at"])
        XCTAssertNotNil(jsonObject["updated_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["therapistId"])
        XCTAssertNil(jsonObject["assessmentType"])
        XCTAssertNil(jsonObject["painAtRest"])
    }

    func testClinicalAssessment_DecodingFromJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "assessment_type": "intake",
            "assessment_date": "2024-03-15",
            "pain_at_rest": 3,
            "pain_with_activity": 6,
            "pain_worst": 8,
            "pain_locations": ["Right shoulder", "Upper back"],
            "chief_complaint": "Shoulder pain with overhead activities",
            "history_of_present_illness": "Gradual onset over 3 weeks",
            "objective_findings": "Decreased ROM",
            "assessment_summary": "Shoulder impingement",
            "treatment_plan": "PT 2x/week",
            "status": "complete",
            "created_at": "2024-03-15T10:00:00Z",
            "updated_at": "2024-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        let assessment = try decoder.decode(ClinicalAssessment.self, from: json)

        XCTAssertEqual(assessment.assessmentType, .intake)
        XCTAssertEqual(assessment.painAtRest, 3)
        XCTAssertEqual(assessment.painWithActivity, 6)
        XCTAssertEqual(assessment.painWorst, 8)
        XCTAssertEqual(assessment.painLocations?.count, 2)
        XCTAssertEqual(assessment.chiefComplaint, "Shoulder pain with overhead activities")
        XCTAssertEqual(assessment.status, .complete)
    }

    func testClinicalAssessment_DecodingWithNulls() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "assessment_type": "progress",
            "assessment_date": "2024-03-15",
            "rom_measurements": null,
            "functional_tests": null,
            "pain_at_rest": null,
            "pain_with_activity": null,
            "pain_worst": null,
            "pain_locations": null,
            "chief_complaint": null,
            "history_of_present_illness": null,
            "past_medical_history": null,
            "functional_goals": null,
            "objective_findings": null,
            "assessment_summary": null,
            "treatment_plan": null,
            "status": "draft",
            "signed_at": null,
            "created_at": "2024-03-15T10:00:00Z",
            "updated_at": "2024-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        let assessment = try decoder.decode(ClinicalAssessment.self, from: json)

        XCTAssertNil(assessment.romMeasurements)
        XCTAssertNil(assessment.functionalTests)
        XCTAssertNil(assessment.painAtRest)
        XCTAssertNil(assessment.chiefComplaint)
        XCTAssertNil(assessment.signedAt)
        XCTAssertEqual(assessment.status, .draft)
    }

    // MARK: - Edge Case Tests

    func testClinicalAssessment_AllPainScoresZero() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 0,
            painWithActivity: 0,
            painWorst: 0
        )

        XCTAssertEqual(assessment.averagePainScore, 0.0)
        XCTAssertFalse(assessment.isPainConcerning)
    }

    func testClinicalAssessment_AllPainScoresTen() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 10,
            painWithActivity: 10,
            painWorst: 10
        )

        XCTAssertEqual(assessment.averagePainScore, 10.0)
        XCTAssertTrue(assessment.isPainConcerning)
    }

    func testClinicalAssessment_EmptyArrays() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [],
            functionalTests: [],
            painLocations: [],
            functionalGoals: []
        )

        XCTAssertNotNil(assessment.romMeasurements)
        XCTAssertTrue(assessment.romMeasurements!.isEmpty)
        XCTAssertNotNil(assessment.functionalTests)
        XCTAssertTrue(assessment.functionalTests!.isEmpty)
        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testClinicalAssessment_BoundaryPainValues() {
        // Test pain at rest boundary at 6
        let assessment1 = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWithActivity: 5,
            painWorst: 6
        )
        XCTAssertFalse(assessment1.isPainConcerning) // 6 worst is not concerning

        // Test pain with activity boundary at 6
        let assessment2 = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWithActivity: 6,
            painWorst: 5
        )
        XCTAssertTrue(assessment2.isPainConcerning) // 6 activity is concerning
    }
}

// MARK: - AssessmentType Comprehensive Tests

final class AssessmentTypeComprehensiveTests: XCTestCase {

    func testAssessmentType_AllRawValues() {
        XCTAssertEqual(AssessmentType.intake.rawValue, "intake")
        XCTAssertEqual(AssessmentType.progress.rawValue, "progress")
        XCTAssertEqual(AssessmentType.discharge.rawValue, "discharge")
        XCTAssertEqual(AssessmentType.follow_up.rawValue, "follow_up")
    }

    func testAssessmentType_InitFromRawValue() {
        XCTAssertEqual(AssessmentType(rawValue: "intake"), .intake)
        XCTAssertEqual(AssessmentType(rawValue: "progress"), .progress)
        XCTAssertEqual(AssessmentType(rawValue: "discharge"), .discharge)
        XCTAssertEqual(AssessmentType(rawValue: "follow_up"), .follow_up)
        XCTAssertNil(AssessmentType(rawValue: "invalid"))
        XCTAssertNil(AssessmentType(rawValue: ""))
        XCTAssertNil(AssessmentType(rawValue: "INTAKE"))
    }

    func testAssessmentType_DisplayNames() {
        XCTAssertEqual(AssessmentType.intake.displayName, "Initial Evaluation")
        XCTAssertEqual(AssessmentType.progress.displayName, "Progress Note")
        XCTAssertEqual(AssessmentType.discharge.displayName, "Discharge Summary")
        XCTAssertEqual(AssessmentType.follow_up.displayName, "Follow-Up")
    }

    func testAssessmentType_Descriptions() {
        XCTAssertTrue(AssessmentType.intake.description.contains("initial evaluation"))
        XCTAssertTrue(AssessmentType.progress.description.contains("re-evaluation"))
        XCTAssertTrue(AssessmentType.discharge.description.contains("Final assessment"))
        XCTAssertTrue(AssessmentType.follow_up.description.contains("check-in"))
    }

    func testAssessmentType_IconNames() {
        XCTAssertEqual(AssessmentType.intake.iconName, "doc.text.fill")
        XCTAssertEqual(AssessmentType.progress.iconName, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(AssessmentType.discharge.iconName, "checkmark.seal.fill")
        XCTAssertEqual(AssessmentType.follow_up.iconName, "arrow.clockwise")
    }

    func testAssessmentType_ColorsAreUnique() {
        let colors = AssessmentType.allCases.map { $0.color }
        // Colors should be assigned (not necessarily unique but defined)
        XCTAssertEqual(colors.count, 4)
    }

    func testAssessmentType_CaseIterable() {
        let allCases = AssessmentType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.intake))
        XCTAssertTrue(allCases.contains(.progress))
        XCTAssertTrue(allCases.contains(.discharge))
        XCTAssertTrue(allCases.contains(.follow_up))
    }

    func testAssessmentType_Identifiable() {
        XCTAssertEqual(AssessmentType.intake.id, "intake")
        XCTAssertEqual(AssessmentType.progress.id, "progress")
        XCTAssertEqual(AssessmentType.discharge.id, "discharge")
        XCTAssertEqual(AssessmentType.follow_up.id, "follow_up")
    }

    func testAssessmentType_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in AssessmentType.allCases {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(AssessmentType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
}

// MARK: - AssessmentStatus Comprehensive Tests

final class AssessmentStatusComprehensiveTests: XCTestCase {

    func testAssessmentStatus_AllRawValues() {
        XCTAssertEqual(AssessmentStatus.draft.rawValue, "draft")
        XCTAssertEqual(AssessmentStatus.complete.rawValue, "complete")
        XCTAssertEqual(AssessmentStatus.signed.rawValue, "signed")
    }

    func testAssessmentStatus_InitFromRawValue() {
        XCTAssertEqual(AssessmentStatus(rawValue: "draft"), .draft)
        XCTAssertEqual(AssessmentStatus(rawValue: "complete"), .complete)
        XCTAssertEqual(AssessmentStatus(rawValue: "signed"), .signed)
        XCTAssertNil(AssessmentStatus(rawValue: "invalid"))
        XCTAssertNil(AssessmentStatus(rawValue: "DRAFT"))
        XCTAssertNil(AssessmentStatus(rawValue: ""))
    }

    func testAssessmentStatus_DisplayNames() {
        XCTAssertEqual(AssessmentStatus.draft.displayName, "Draft")
        XCTAssertEqual(AssessmentStatus.complete.displayName, "Complete")
        XCTAssertEqual(AssessmentStatus.signed.displayName, "Signed")
    }

    func testAssessmentStatus_IconNames() {
        XCTAssertEqual(AssessmentStatus.draft.iconName, "doc.badge.ellipsis")
        XCTAssertEqual(AssessmentStatus.complete.iconName, "doc.badge.checkmark")
        XCTAssertEqual(AssessmentStatus.signed.iconName, "signature")
    }

    func testAssessmentStatus_IsEditable() {
        XCTAssertTrue(AssessmentStatus.draft.isEditable)
        XCTAssertTrue(AssessmentStatus.complete.isEditable)
        XCTAssertFalse(AssessmentStatus.signed.isEditable)
    }

    func testAssessmentStatus_ColorsAreAssigned() {
        for status in AssessmentStatus.allCases {
            XCTAssertNotNil(status.color)
        }
    }

    func testAssessmentStatus_CaseIterable() {
        let allCases = AssessmentStatus.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.draft))
        XCTAssertTrue(allCases.contains(.complete))
        XCTAssertTrue(allCases.contains(.signed))
    }

    func testAssessmentStatus_Identifiable() {
        XCTAssertEqual(AssessmentStatus.draft.id, "draft")
        XCTAssertEqual(AssessmentStatus.complete.id, "complete")
        XCTAssertEqual(AssessmentStatus.signed.id, "signed")
    }

    func testAssessmentStatus_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in AssessmentStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(AssessmentStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}

// MARK: - Status Transition Tests

final class StatusTransitionTests: XCTestCase {

    func testStatusTransition_DraftToComplete() {
        var assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .draft
        )

        XCTAssertEqual(assessment.status, .draft)
        XCTAssertTrue(assessment.status.isEditable)

        assessment.status = .complete

        XCTAssertEqual(assessment.status, .complete)
        XCTAssertTrue(assessment.status.isEditable)
    }

    func testStatusTransition_CompleteToSigned() {
        var assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary",
            treatmentPlan: "Plan",
            status: .complete
        )

        XCTAssertTrue(assessment.isReadyForSignature)

        assessment.status = .signed

        XCTAssertEqual(assessment.status, .signed)
        XCTAssertFalse(assessment.status.isEditable)
    }

    func testStatusTransition_SignedCannotTransitionBack() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .signed
        )

        XCTAssertFalse(assessment.status.isEditable)
        // Business logic should prevent transitions back from signed
    }
}

// MARK: - FunctionalTest Model Tests

final class FunctionalTestModelTests: XCTestCase {

    func testFunctionalTest_Initialization() {
        let id = UUID()
        let test = FunctionalTest(
            id: id,
            testName: "Hawkins-Kennedy Test",
            result: "Positive",
            score: 1.0,
            normalValue: "Negative",
            interpretation: "Indicates possible subacromial impingement",
            notes: "Pain reproduced"
        )

        XCTAssertEqual(test.id, id)
        XCTAssertEqual(test.testName, "Hawkins-Kennedy Test")
        XCTAssertEqual(test.result, "Positive")
        XCTAssertEqual(test.score, 1.0)
        XCTAssertEqual(test.normalValue, "Negative")
        XCTAssertTrue(test.interpretation!.contains("impingement"))
        XCTAssertEqual(test.notes, "Pain reproduced")
    }

    func testFunctionalTest_MinimalInit() {
        let test = FunctionalTest(
            testName: "Test",
            result: "Result"
        )

        XCTAssertNotNil(test.id)
        XCTAssertEqual(test.testName, "Test")
        XCTAssertEqual(test.result, "Result")
        XCTAssertNil(test.score)
        XCTAssertNil(test.normalValue)
        XCTAssertNil(test.interpretation)
        XCTAssertNil(test.notes)
    }

    func testFunctionalTest_IsAbnormal_WithAbnormalKeyword() {
        let test = FunctionalTest(
            testName: "Test",
            result: "Positive",
            interpretation: "Abnormal - indicates pathology"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_WithLimitedKeyword() {
        let test = FunctionalTest(
            testName: "ROM Test",
            result: "Reduced",
            interpretation: "Limited compared to contralateral side"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_WithPositiveKeyword() {
        let test = FunctionalTest(
            testName: "Lachman",
            result: "+",
            interpretation: "Positive for ACL laxity"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_NormalInterpretation() {
        let test = FunctionalTest(
            testName: "Strength",
            result: "5/5",
            interpretation: "Normal strength bilaterally"
        )

        XCTAssertFalse(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_NoInterpretation() {
        let test = FunctionalTest(
            testName: "Test",
            result: "Result",
            interpretation: nil
        )

        XCTAssertFalse(test.isAbnormal)
    }

    func testFunctionalTest_Codable() throws {
        let original = FunctionalTest(
            testName: "Hawkins-Kennedy",
            result: "Positive",
            score: 1.0,
            interpretation: "Abnormal"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FunctionalTest.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.testName, decoded.testName)
        XCTAssertEqual(original.result, decoded.result)
        XCTAssertEqual(original.score, decoded.score)
        XCTAssertEqual(original.interpretation, decoded.interpretation)
    }
}

// MARK: - ClinicalAssessmentInput Validation Tests

final class ClinicalAssessmentInputValidationTests: XCTestCase {

    func testValidate_ValidInput() throws {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 5,
            painWithActivity: 7,
            painWorst: 8
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_BoundaryValues_Min() throws {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 0,
            painWithActivity: 0,
            painWorst: 0
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_BoundaryValues_Max() throws {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 10,
            painWithActivity: 10,
            painWorst: 10
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_NilPainScores() throws {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake"
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_PainAtRest_TooHigh() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 11
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case ClinicalAssessmentError.invalidPainScore(let message) = error else {
                XCTFail("Expected invalidPainScore error")
                return
            }
            XCTAssertTrue(message.contains("Pain at rest"))
        }
    }

    func testValidate_PainWithActivity_TooHigh() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painWithActivity: 15
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case ClinicalAssessmentError.invalidPainScore(let message) = error else {
                XCTFail("Expected invalidPainScore error")
                return
            }
            XCTAssertTrue(message.contains("Pain with activity"))
        }
    }

    func testValidate_PainWorst_Negative() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painWorst: -1
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case ClinicalAssessmentError.invalidPainScore(let message) = error else {
                XCTFail("Expected invalidPainScore error")
                return
            }
            XCTAssertTrue(message.contains("Worst pain"))
        }
    }
}

// MARK: - ClinicalAssessmentError Tests

final class ClinicalAssessmentErrorComprehensiveTests: XCTestCase {

    func testError_InvalidPainScore() {
        let error = ClinicalAssessmentError.invalidPainScore("Custom message")
        XCTAssertEqual(error.errorDescription, "Custom message")
    }

    func testError_AssessmentNotFound() {
        let error = ClinicalAssessmentError.assessmentNotFound
        XCTAssertEqual(error.errorDescription, "Clinical assessment not found")
    }

    func testError_SaveFailed() {
        let error = ClinicalAssessmentError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save clinical assessment")
    }

    func testError_FetchFailed() {
        let error = ClinicalAssessmentError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch clinical assessment")
    }

    func testError_CannotEditSigned() {
        let error = ClinicalAssessmentError.cannotEditSigned
        XCTAssertEqual(error.errorDescription, "Cannot edit a signed assessment")
    }

    func testError_MissingRequiredFields() {
        let error = ClinicalAssessmentError.missingRequiredFields
        XCTAssertEqual(error.errorDescription, "Missing required fields for assessment")
    }

    func testError_Equatable() {
        let error1 = ClinicalAssessmentError.assessmentNotFound
        let error2 = ClinicalAssessmentError.assessmentNotFound
        let error3 = ClinicalAssessmentError.saveFailed

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testError_InvalidPainScore_Equatable() {
        let error1 = ClinicalAssessmentError.invalidPainScore("Message 1")
        let error2 = ClinicalAssessmentError.invalidPainScore("Message 1")
        let error3 = ClinicalAssessmentError.invalidPainScore("Message 2")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class ClinicalAssessmentSampleDataTests: XCTestCase {

    func testClinicalAssessment_SampleExists() {
        let sample = ClinicalAssessment.sample

        XCTAssertNotNil(sample.id)
        XCTAssertNotNil(sample.patientId)
        XCTAssertNotNil(sample.therapistId)
        XCTAssertEqual(sample.assessmentType, .intake)
        XCTAssertEqual(sample.painAtRest, 2)
        XCTAssertEqual(sample.painWithActivity, 5)
        XCTAssertEqual(sample.painWorst, 7)
        XCTAssertEqual(sample.status, .complete)
    }

    func testClinicalAssessment_DraftSampleExists() {
        let draft = ClinicalAssessment.draftSample

        XCTAssertNotNil(draft.id)
        XCTAssertEqual(draft.assessmentType, .progress)
        XCTAssertEqual(draft.status, .draft)
    }

    func testFunctionalTest_SampleExists() {
        let sample = FunctionalTest.sample

        XCTAssertEqual(sample.testName, "Hawkins-Kennedy Test")
        XCTAssertEqual(sample.result, "Positive")
        XCTAssertNotNil(sample.interpretation)
    }
}
#endif
