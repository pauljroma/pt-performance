//
//  OutcomeMeasureTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for OutcomeMeasure model
//  Tests score calculations, improvement tracking, measure types (DASH, VAS, etc.)
//

import XCTest
@testable import PTPerformance

// MARK: - OutcomeMeasure Model Tests

final class OutcomeMeasureModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testOutcomeMeasure_DefaultInitialization() {
        let patientId = UUID()
        let therapistId = UUID()
        let responses = ["q1": 3, "q2": 4, "q3": 3]

        let measure = OutcomeMeasure(
            patientId: patientId,
            therapistId: therapistId,
            measureType: .LEFS,
            responses: responses
        )

        XCTAssertNotNil(measure.id)
        XCTAssertEqual(measure.patientId, patientId)
        XCTAssertEqual(measure.therapistId, therapistId)
        XCTAssertNil(measure.clinicalAssessmentId)
        XCTAssertEqual(measure.measureType, .LEFS)
        XCTAssertEqual(measure.responses, responses)
        XCTAssertNil(measure.rawScore)
        XCTAssertNil(measure.normalizedScore)
        XCTAssertNil(measure.interpretation)
        XCTAssertNil(measure.previousScore)
        XCTAssertNil(measure.changeFromPrevious)
        XCTAssertNil(measure.meetsMcid)
        XCTAssertNil(measure.notes)
    }

    func testOutcomeMeasure_FullInitialization() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let clinicalAssessmentId = UUID()
        let assessmentDate = Date()
        let createdAt = Date()
        let responses = ["q1": 3, "q2": 4]

        let measure = OutcomeMeasure(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            clinicalAssessmentId: clinicalAssessmentId,
            measureType: .DASH,
            assessmentDate: assessmentDate,
            responses: responses,
            rawScore: 35.0,
            normalizedScore: 35.0,
            interpretation: "Mild to moderate disability",
            previousScore: 50.0,
            changeFromPrevious: -15.0,
            meetsMcid: true,
            notes: "Patient showing improvement",
            createdAt: createdAt
        )

        XCTAssertEqual(measure.id, id)
        XCTAssertEqual(measure.patientId, patientId)
        XCTAssertEqual(measure.therapistId, therapistId)
        XCTAssertEqual(measure.clinicalAssessmentId, clinicalAssessmentId)
        XCTAssertEqual(measure.measureType, .DASH)
        XCTAssertEqual(measure.assessmentDate, assessmentDate)
        XCTAssertEqual(measure.responses, responses)
        XCTAssertEqual(measure.rawScore, 35.0)
        XCTAssertEqual(measure.normalizedScore, 35.0)
        XCTAssertEqual(measure.interpretation, "Mild to moderate disability")
        XCTAssertEqual(measure.previousScore, 50.0)
        XCTAssertEqual(measure.changeFromPrevious, -15.0)
        XCTAssertEqual(measure.meetsMcid, true)
        XCTAssertEqual(measure.notes, "Patient showing improvement")
    }

    // MARK: - Score Calculations Tests

    func testOutcomeMeasure_FormattedScore_WithNormalizedScore() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            rawScore: 65.0,
            normalizedScore: 81.25
        )

        XCTAssertEqual(measure.formattedScore, "81.3")
    }

    func testOutcomeMeasure_FormattedScore_WithRawScoreOnly() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .VAS,
            responses: [:],
            rawScore: 45.0
        )

        XCTAssertEqual(measure.formattedScore, "45.0")
    }

    func testOutcomeMeasure_FormattedScore_NoScore() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .NPRS,
            responses: [:]
        )

        XCTAssertEqual(measure.formattedScore, "N/A")
    }

    // MARK: - Improvement Tracking Tests

    func testOutcomeMeasure_ShowsImprovement_HigherIsBetter() {
        // LEFS: higher scores are better, MCID = 9.0
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 70.0,
            changeFromPrevious: 12.0 // Greater than MCID of 9.0
        )

        XCTAssertTrue(measure.showsImprovement)
        XCTAssertFalse(measure.showsDecline)
    }

    func testOutcomeMeasure_ShowsImprovement_LowerIsBetter() {
        // DASH: lower scores are better, MCID = 10.8
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .DASH,
            responses: [:],
            normalizedScore: 25.0,
            changeFromPrevious: -15.0 // Decrease greater than MCID
        )

        XCTAssertTrue(measure.showsImprovement)
        XCTAssertFalse(measure.showsDecline)
    }

    func testOutcomeMeasure_ShowsDecline_HigherIsBetter() {
        // LEFS: higher scores are better
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 50.0,
            changeFromPrevious: -12.0 // Decrease greater than MCID
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertTrue(measure.showsDecline)
    }

    func testOutcomeMeasure_ShowsDecline_LowerIsBetter() {
        // DASH: lower scores are better
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .DASH,
            responses: [:],
            normalizedScore: 45.0,
            changeFromPrevious: 15.0 // Increase greater than MCID
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertTrue(measure.showsDecline)
    }

    func testOutcomeMeasure_Stable_NoMeaningfulChange() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 60.0,
            changeFromPrevious: 3.0 // Less than MCID of 9.0
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertFalse(measure.showsDecline)
    }

    func testOutcomeMeasure_NoChange_NilValue() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 60.0,
            changeFromPrevious: nil
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertFalse(measure.showsDecline)
    }

    // MARK: - Progress Status Tests

    func testOutcomeMeasure_ProgressStatus_Improving() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 70.0,
            changeFromPrevious: 15.0
        )

        XCTAssertEqual(measure.progressStatus, .improving)
    }

    func testOutcomeMeasure_ProgressStatus_Stable() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 60.0,
            changeFromPrevious: 2.0
        )

        XCTAssertEqual(measure.progressStatus, .stable)
    }

    func testOutcomeMeasure_ProgressStatus_Declining() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 50.0,
            changeFromPrevious: -15.0
        )

        XCTAssertEqual(measure.progressStatus, .declining)
    }

    // MARK: - Severity Level Tests

    func testOutcomeMeasure_SeverityLevel_Minimal_HigherIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS, // maxScore = 80, higherIsBetter = true
            responses: [:],
            normalizedScore: 72.0 // 90% of 80
        )

        XCTAssertEqual(measure.severityLevel, .minimal)
    }

    func testOutcomeMeasure_SeverityLevel_Mild_HigherIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS, // maxScore = 80
            responses: [:],
            normalizedScore: 64.0 // 80% of 80
        )

        XCTAssertEqual(measure.severityLevel, .mild)
    }

    func testOutcomeMeasure_SeverityLevel_Moderate_HigherIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 48.0 // 60% of 80
        )

        XCTAssertEqual(measure.severityLevel, .moderate)
    }

    func testOutcomeMeasure_SeverityLevel_Severe_HigherIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 24.0 // 30% of 80
        )

        XCTAssertEqual(measure.severityLevel, .severe)
    }

    func testOutcomeMeasure_SeverityLevel_Complete_HigherIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 8.0 // 10% of 80
        )

        XCTAssertEqual(measure.severityLevel, .complete)
    }

    func testOutcomeMeasure_SeverityLevel_Minimal_LowerIsBetter() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .DASH, // maxScore = 100, higherIsBetter = false
            responses: [:],
            normalizedScore: 5.0 // Low score means high percentage when inverted
        )

        XCTAssertEqual(measure.severityLevel, .minimal)
    }

    func testOutcomeMeasure_SeverityLevel_Unknown_NoScore() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:]
        )

        XCTAssertEqual(measure.severityLevel, .unknown)
    }

    // MARK: - Formatted Date Tests

    func testOutcomeMeasure_FormattedDate_ReturnsNonEmpty() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:]
        )

        XCTAssertFalse(measure.formattedDate.isEmpty)
    }

    // MARK: - Status Color Tests

    func testOutcomeMeasure_StatusColor_Improving() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 70.0,
            changeFromPrevious: 15.0
        )

        XCTAssertNotNil(measure.statusColor)
    }

    // MARK: - Encoding/Decoding Tests

    func testOutcomeMeasure_EncodeDecode() throws {
        let original = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .DASH,
            responses: ["q1": 2, "q2": 3],
            rawScore: 35.0,
            normalizedScore: 35.0,
            previousScore: 50.0,
            changeFromPrevious: -15.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(OutcomeMeasure.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.measureType, decoded.measureType)
        XCTAssertEqual(original.responses, decoded.responses)
        XCTAssertEqual(original.rawScore, decoded.rawScore)
        XCTAssertEqual(original.normalizedScore, decoded.normalizedScore)
        XCTAssertEqual(original.previousScore, decoded.previousScore)
        XCTAssertEqual(original.changeFromPrevious, decoded.changeFromPrevious)
    }

    func testOutcomeMeasure_CodingKeysMapping() throws {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: ["q1": 3],
            rawScore: 60.0,
            changeFromPrevious: 10.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(measure)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["therapist_id"])
        XCTAssertNotNil(jsonObject["measure_type"])
        XCTAssertNotNil(jsonObject["assessment_date"])
        XCTAssertNotNil(jsonObject["raw_score"])
        XCTAssertNotNil(jsonObject["change_from_previous"])
        XCTAssertNotNil(jsonObject["created_at"])

        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["measureType"])
        XCTAssertNil(jsonObject["rawScore"])
    }

    func testOutcomeMeasure_DecodingFromJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "clinical_assessment_id": null,
            "measure_type": "LEFS",
            "assessment_date": "2024-03-15T10:00:00Z",
            "responses": {"q1": 3, "q2": 4},
            "raw_score": 68.0,
            "normalized_score": 85.0,
            "interpretation": "Good functional level",
            "previous_score": 54.0,
            "change_from_previous": 14.0,
            "meets_mcid": true,
            "notes": "Improved since last visit",
            "created_at": "2024-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let measure = try decoder.decode(OutcomeMeasure.self, from: json)

        XCTAssertEqual(measure.measureType, .LEFS)
        XCTAssertEqual(measure.rawScore, 68.0)
        XCTAssertEqual(measure.normalizedScore, 85.0)
        XCTAssertEqual(measure.interpretation, "Good functional level")
        XCTAssertEqual(measure.previousScore, 54.0)
        XCTAssertEqual(measure.changeFromPrevious, 14.0)
        XCTAssertEqual(measure.meetsMcid, true)
        XCTAssertEqual(measure.notes, "Improved since last visit")
    }

    func testOutcomeMeasure_DecodingWithNulls() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "clinical_assessment_id": null,
            "measure_type": "VAS",
            "assessment_date": "2024-03-15T10:00:00Z",
            "responses": {},
            "raw_score": null,
            "normalized_score": null,
            "interpretation": null,
            "previous_score": null,
            "change_from_previous": null,
            "meets_mcid": null,
            "notes": null,
            "created_at": "2024-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let measure = try decoder.decode(OutcomeMeasure.self, from: json)

        XCTAssertNil(measure.clinicalAssessmentId)
        XCTAssertNil(measure.rawScore)
        XCTAssertNil(measure.normalizedScore)
        XCTAssertNil(measure.interpretation)
        XCTAssertNil(measure.previousScore)
        XCTAssertNil(measure.changeFromPrevious)
        XCTAssertNil(measure.meetsMcid)
        XCTAssertNil(measure.notes)
    }
}

// MARK: - OutcomeMeasureType Comprehensive Tests

final class OutcomeMeasureTypeComprehensiveTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testOutcomeMeasureType_AllRawValues() {
        XCTAssertEqual(OutcomeMeasureType.LEFS.rawValue, "LEFS")
        XCTAssertEqual(OutcomeMeasureType.DASH.rawValue, "DASH")
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.rawValue, "QuickDASH")
        XCTAssertEqual(OutcomeMeasureType.PSFS.rawValue, "PSFS")
        XCTAssertEqual(OutcomeMeasureType.OMAK.rawValue, "OMAK")
        XCTAssertEqual(OutcomeMeasureType.VAS.rawValue, "VAS")
        XCTAssertEqual(OutcomeMeasureType.NDI.rawValue, "NDI")
        XCTAssertEqual(OutcomeMeasureType.ODI.rawValue, "ODI")
        XCTAssertEqual(OutcomeMeasureType.NPRS.rawValue, "NPRS")
        XCTAssertEqual(OutcomeMeasureType.KOOS.rawValue, "KOOS")
        XCTAssertEqual(OutcomeMeasureType.WOMAC.rawValue, "WOMAC")
        XCTAssertEqual(OutcomeMeasureType.SF36.rawValue, "SF36")
    }

    func testOutcomeMeasureType_InitFromRawValue() {
        XCTAssertEqual(OutcomeMeasureType(rawValue: "LEFS"), .LEFS)
        XCTAssertEqual(OutcomeMeasureType(rawValue: "DASH"), .DASH)
        XCTAssertEqual(OutcomeMeasureType(rawValue: "QuickDASH"), .QuickDASH)
        XCTAssertEqual(OutcomeMeasureType(rawValue: "VAS"), .VAS)
        XCTAssertNil(OutcomeMeasureType(rawValue: "invalid"))
        XCTAssertNil(OutcomeMeasureType(rawValue: "lefs")) // Case sensitive
    }

    // MARK: - Display Name Tests

    func testOutcomeMeasureType_DisplayNames() {
        XCTAssertEqual(OutcomeMeasureType.LEFS.displayName, "Lower Extremity Functional Scale")
        XCTAssertEqual(OutcomeMeasureType.DASH.displayName, "Disabilities of Arm, Shoulder and Hand")
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.displayName, "Quick DASH")
        XCTAssertEqual(OutcomeMeasureType.PSFS.displayName, "Patient-Specific Functional Scale")
        XCTAssertEqual(OutcomeMeasureType.VAS.displayName, "Visual Analog Scale")
        XCTAssertEqual(OutcomeMeasureType.NDI.displayName, "Neck Disability Index")
        XCTAssertEqual(OutcomeMeasureType.ODI.displayName, "Oswestry Disability Index")
        XCTAssertEqual(OutcomeMeasureType.NPRS.displayName, "Numeric Pain Rating Scale")
        XCTAssertEqual(OutcomeMeasureType.KOOS.displayName, "Knee Injury and Osteoarthritis Outcome Score")
        XCTAssertEqual(OutcomeMeasureType.WOMAC.displayName, "WOMAC Osteoarthritis Index")
        XCTAssertEqual(OutcomeMeasureType.SF36.displayName, "SF-36 Health Survey")
    }

    // MARK: - Question Count Tests

    func testOutcomeMeasureType_QuestionCounts() {
        XCTAssertEqual(OutcomeMeasureType.LEFS.questionCount, 20)
        XCTAssertEqual(OutcomeMeasureType.DASH.questionCount, 30)
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.questionCount, 11)
        XCTAssertEqual(OutcomeMeasureType.PSFS.questionCount, 3)
        XCTAssertEqual(OutcomeMeasureType.OMAK.questionCount, 12)
        XCTAssertEqual(OutcomeMeasureType.VAS.questionCount, 1)
        XCTAssertEqual(OutcomeMeasureType.NDI.questionCount, 10)
        XCTAssertEqual(OutcomeMeasureType.ODI.questionCount, 10)
        XCTAssertEqual(OutcomeMeasureType.NPRS.questionCount, 1)
        XCTAssertEqual(OutcomeMeasureType.KOOS.questionCount, 42)
        XCTAssertEqual(OutcomeMeasureType.WOMAC.questionCount, 24)
        XCTAssertEqual(OutcomeMeasureType.SF36.questionCount, 36)
    }

    // MARK: - Max Score Tests

    func testOutcomeMeasureType_MaxScores() {
        XCTAssertEqual(OutcomeMeasureType.LEFS.maxScore, 80)
        XCTAssertEqual(OutcomeMeasureType.DASH.maxScore, 100)
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.maxScore, 100)
        XCTAssertEqual(OutcomeMeasureType.PSFS.maxScore, 10)
        XCTAssertEqual(OutcomeMeasureType.OMAK.maxScore, 100)
        XCTAssertEqual(OutcomeMeasureType.VAS.maxScore, 100)
        XCTAssertEqual(OutcomeMeasureType.NDI.maxScore, 50)
        XCTAssertEqual(OutcomeMeasureType.ODI.maxScore, 50)
        XCTAssertEqual(OutcomeMeasureType.NPRS.maxScore, 10)
        XCTAssertEqual(OutcomeMeasureType.KOOS.maxScore, 100)
        XCTAssertEqual(OutcomeMeasureType.WOMAC.maxScore, 96)
        XCTAssertEqual(OutcomeMeasureType.SF36.maxScore, 100)
    }

    // MARK: - MCID Threshold Tests

    func testOutcomeMeasureType_MCIDThresholds() {
        XCTAssertEqual(OutcomeMeasureType.LEFS.mcidThreshold, 9.0)
        XCTAssertEqual(OutcomeMeasureType.DASH.mcidThreshold, 10.8)
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.mcidThreshold, 8.0)
        XCTAssertEqual(OutcomeMeasureType.PSFS.mcidThreshold, 2.0)
        XCTAssertEqual(OutcomeMeasureType.OMAK.mcidThreshold, 10.0)
        XCTAssertEqual(OutcomeMeasureType.VAS.mcidThreshold, 20.0)
        XCTAssertEqual(OutcomeMeasureType.NDI.mcidThreshold, 7.5)
        XCTAssertEqual(OutcomeMeasureType.ODI.mcidThreshold, 10.0)
        XCTAssertEqual(OutcomeMeasureType.NPRS.mcidThreshold, 2.0)
        XCTAssertEqual(OutcomeMeasureType.KOOS.mcidThreshold, 8.0)
        XCTAssertEqual(OutcomeMeasureType.WOMAC.mcidThreshold, 9.0)
        XCTAssertEqual(OutcomeMeasureType.SF36.mcidThreshold, 5.0)
    }

    // MARK: - Higher Is Better Tests

    func testOutcomeMeasureType_HigherIsBetter() {
        // Measures where higher scores mean better function
        XCTAssertTrue(OutcomeMeasureType.LEFS.higherIsBetter)
        XCTAssertTrue(OutcomeMeasureType.PSFS.higherIsBetter)
        XCTAssertTrue(OutcomeMeasureType.KOOS.higherIsBetter)
        XCTAssertTrue(OutcomeMeasureType.SF36.higherIsBetter)

        // Measures where lower scores mean better function (disability measures)
        XCTAssertFalse(OutcomeMeasureType.DASH.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.QuickDASH.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.OMAK.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.VAS.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.NDI.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.ODI.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.NPRS.higherIsBetter)
        XCTAssertFalse(OutcomeMeasureType.WOMAC.higherIsBetter)
    }

    // MARK: - Body Region Tests

    func testOutcomeMeasureType_BodyRegions() {
        // Lower Extremity
        XCTAssertEqual(OutcomeMeasureType.LEFS.bodyRegion, "Lower Extremity")
        XCTAssertEqual(OutcomeMeasureType.KOOS.bodyRegion, "Lower Extremity")
        XCTAssertEqual(OutcomeMeasureType.WOMAC.bodyRegion, "Lower Extremity")

        // Upper Extremity
        XCTAssertEqual(OutcomeMeasureType.DASH.bodyRegion, "Upper Extremity")
        XCTAssertEqual(OutcomeMeasureType.QuickDASH.bodyRegion, "Upper Extremity")

        // Spine
        XCTAssertEqual(OutcomeMeasureType.NDI.bodyRegion, "Cervical Spine")
        XCTAssertEqual(OutcomeMeasureType.ODI.bodyRegion, "Lumbar Spine")

        // General
        XCTAssertEqual(OutcomeMeasureType.PSFS.bodyRegion, "General")
        XCTAssertEqual(OutcomeMeasureType.VAS.bodyRegion, "General")
        XCTAssertEqual(OutcomeMeasureType.NPRS.bodyRegion, "General")
        XCTAssertEqual(OutcomeMeasureType.SF36.bodyRegion, "General")
        XCTAssertEqual(OutcomeMeasureType.OMAK.bodyRegion, "General")
    }

    // MARK: - Description Tests

    func testOutcomeMeasureType_Descriptions_NotEmpty() {
        for type in OutcomeMeasureType.allCases {
            XCTAssertFalse(type.description.isEmpty, "\(type.rawValue) should have a description")
        }
    }

    func testOutcomeMeasureType_Descriptions_Content() {
        XCTAssertTrue(OutcomeMeasureType.LEFS.description.contains("lower extremity"))
        XCTAssertTrue(OutcomeMeasureType.DASH.description.contains("upper extremity"))
        XCTAssertTrue(OutcomeMeasureType.VAS.description.contains("pain"))
        XCTAssertTrue(OutcomeMeasureType.NDI.description.contains("neck"))
        XCTAssertTrue(OutcomeMeasureType.ODI.description.contains("low back"))
    }

    // MARK: - CaseIterable Tests

    func testOutcomeMeasureType_CaseIterable() {
        let allCases = OutcomeMeasureType.allCases
        XCTAssertEqual(allCases.count, 12)
        XCTAssertTrue(allCases.contains(.LEFS))
        XCTAssertTrue(allCases.contains(.DASH))
        XCTAssertTrue(allCases.contains(.VAS))
        XCTAssertTrue(allCases.contains(.NDI))
        XCTAssertTrue(allCases.contains(.ODI))
    }

    // MARK: - Identifiable Tests

    func testOutcomeMeasureType_Identifiable() {
        for type in OutcomeMeasureType.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }

    // MARK: - Codable Tests

    func testOutcomeMeasureType_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in OutcomeMeasureType.allCases {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(OutcomeMeasureType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Color Tests

    func testOutcomeMeasureType_ColorsAssigned() {
        for type in OutcomeMeasureType.allCases {
            XCTAssertNotNil(type.color)
        }
    }
}

// MARK: - ProgressStatus Tests

final class ProgressStatusComprehensiveTests: XCTestCase {

    func testProgressStatus_AllRawValues() {
        XCTAssertEqual(ProgressStatus.improving.rawValue, "improving")
        XCTAssertEqual(ProgressStatus.stable.rawValue, "stable")
        XCTAssertEqual(ProgressStatus.declining.rawValue, "declining")
    }

    func testProgressStatus_DisplayNames() {
        XCTAssertEqual(ProgressStatus.improving.displayName, "Improving")
        XCTAssertEqual(ProgressStatus.stable.displayName, "Stable")
        XCTAssertEqual(ProgressStatus.declining.displayName, "Declining")
    }

    func testProgressStatus_IconNames() {
        XCTAssertEqual(ProgressStatus.improving.iconName, "arrow.up.right")
        XCTAssertEqual(ProgressStatus.stable.iconName, "arrow.right")
        XCTAssertEqual(ProgressStatus.declining.iconName, "arrow.down.right")
    }

    func testProgressStatus_ColorsAssigned() {
        for status in [ProgressStatus.improving, .stable, .declining] {
            XCTAssertNotNil(status.color)
        }
    }

    func testProgressStatus_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let statuses: [ProgressStatus] = [.improving, .stable, .declining]
        for status in statuses {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(ProgressStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}

// MARK: - SeverityLevel Tests

final class SeverityLevelComprehensiveTests: XCTestCase {

    func testSeverityLevel_AllRawValues() {
        XCTAssertEqual(SeverityLevel.minimal.rawValue, "minimal")
        XCTAssertEqual(SeverityLevel.mild.rawValue, "mild")
        XCTAssertEqual(SeverityLevel.moderate.rawValue, "moderate")
        XCTAssertEqual(SeverityLevel.severe.rawValue, "severe")
        XCTAssertEqual(SeverityLevel.complete.rawValue, "complete")
        XCTAssertEqual(SeverityLevel.unknown.rawValue, "unknown")
    }

    func testSeverityLevel_DisplayNames() {
        XCTAssertEqual(SeverityLevel.minimal.displayName, "Minimal Disability")
        XCTAssertEqual(SeverityLevel.mild.displayName, "Mild Disability")
        XCTAssertEqual(SeverityLevel.moderate.displayName, "Moderate Disability")
        XCTAssertEqual(SeverityLevel.severe.displayName, "Severe Disability")
        XCTAssertEqual(SeverityLevel.complete.displayName, "Complete Disability")
        XCTAssertEqual(SeverityLevel.unknown.displayName, "Unknown")
    }

    func testSeverityLevel_ColorsAssigned() {
        for level in [SeverityLevel.minimal, .mild, .moderate, .severe, .complete, .unknown] {
            XCTAssertNotNil(level.color)
        }
    }

    func testSeverityLevel_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let levels: [SeverityLevel] = [.minimal, .mild, .moderate, .severe, .complete, .unknown]
        for level in levels {
            let data = try encoder.encode(level)
            let decoded = try decoder.decode(SeverityLevel.self, from: data)
            XCTAssertEqual(decoded, level)
        }
    }
}

// MARK: - OutcomeMeasureTrend Tests

final class OutcomeMeasureTrendTests: XCTestCase {

    func testOutcomeMeasureTrend_Decoding() throws {
        let json = """
        {
            "patient_id": "550e8400-e29b-41d4-a716-446655440000",
            "measure_type": "LEFS",
            "measurements": [
                {
                    "id": "660e8400-e29b-41d4-a716-446655440001",
                    "date": "2024-01-15T10:00:00Z",
                    "score": 45.0,
                    "change_from_previous": null
                },
                {
                    "id": "770e8400-e29b-41d4-a716-446655440002",
                    "date": "2024-02-15T10:00:00Z",
                    "score": 58.0,
                    "change_from_previous": 13.0
                }
            ],
            "overall_change": 13.0,
            "trend_direction": "improving",
            "achieved_mcid": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let trend = try decoder.decode(OutcomeMeasureTrend.self, from: json)

        XCTAssertEqual(trend.measureType, .LEFS)
        XCTAssertEqual(trend.measurements.count, 2)
        XCTAssertEqual(trend.overallChange, 13.0)
        XCTAssertEqual(trend.trendDirection, .improving)
        XCTAssertTrue(trend.achievedMcid)
    }

    func testOutcomeMeasureSummary_Properties() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "date": "2024-03-15T10:00:00Z",
            "score": 65.0,
            "change_from_previous": 10.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let summary = try decoder.decode(OutcomeMeasureTrend.OutcomeMeasureSummary.self, from: json)

        XCTAssertNotNil(summary.id)
        XCTAssertEqual(summary.score, 65.0)
        XCTAssertEqual(summary.changeFromPrevious, 10.0)
    }
}

// MARK: - OutcomeMeasureInput Validation Tests

final class OutcomeMeasureInputValidationTests: XCTestCase {

    func testValidate_CompleteResponses() throws {
        var responses: [String: Int] = [:]
        for i in 1...20 {
            responses["q\(i)"] = 3
        }

        let input = OutcomeMeasureInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            measureType: "LEFS",
            responses: responses
        )

        XCTAssertNoThrow(try input.validate(for: .LEFS))
    }

    func testValidate_IncompleteResponses() {
        let input = OutcomeMeasureInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            measureType: "LEFS",
            responses: ["q1": 3, "q2": 4] // Only 2 responses for a 20-question measure
        )

        XCTAssertThrowsError(try input.validate(for: .LEFS)) { error in
            guard case OutcomeMeasureError.incompleteResponses(let message) = error else {
                XCTFail("Expected incompleteResponses error")
                return
            }
            XCTAssertTrue(message.contains("20"))
        }
    }

    func testValidate_VAS_SingleQuestion() throws {
        let input = OutcomeMeasureInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            measureType: "VAS",
            responses: ["q1": 50]
        )

        XCTAssertNoThrow(try input.validate(for: .VAS))
    }

    func testValidate_NPRS_SingleQuestion() throws {
        let input = OutcomeMeasureInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            measureType: "NPRS",
            responses: ["q1": 5]
        )

        XCTAssertNoThrow(try input.validate(for: .NPRS))
    }
}

// MARK: - OutcomeMeasureError Tests

final class OutcomeMeasureErrorComprehensiveTests: XCTestCase {

    func testError_IncompleteResponses() {
        let error = OutcomeMeasureError.incompleteResponses("Please answer all 20 questions")
        XCTAssertEqual(error.errorDescription, "Please answer all 20 questions")
    }

    func testError_MeasureNotFound() {
        let error = OutcomeMeasureError.measureNotFound
        XCTAssertEqual(error.errorDescription, "Outcome measure not found")
    }

    func testError_SaveFailed() {
        let error = OutcomeMeasureError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save outcome measure")
    }

    func testError_FetchFailed() {
        let error = OutcomeMeasureError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch outcome measure")
    }

    func testError_InvalidMeasureType() {
        let error = OutcomeMeasureError.invalidMeasureType
        XCTAssertEqual(error.errorDescription, "Invalid outcome measure type")
    }
}

// MARK: - Edge Case Tests

final class OutcomeMeasureEdgeCaseTests: XCTestCase {

    func testOutcomeMeasure_BoundaryMCID_Improvement() {
        // Exactly at MCID threshold for LEFS (9.0)
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 60.0,
            changeFromPrevious: 9.0 // Exactly at MCID
        )

        XCTAssertTrue(measure.showsImprovement)
        XCTAssertEqual(measure.progressStatus, .improving)
    }

    func testOutcomeMeasure_JustBelowMCID() {
        // Just below MCID threshold for LEFS (9.0)
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            normalizedScore: 60.0,
            changeFromPrevious: 8.9 // Just below MCID
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertEqual(measure.progressStatus, .stable)
    }

    func testOutcomeMeasure_ZeroChange() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .DASH,
            responses: [:],
            normalizedScore: 40.0,
            changeFromPrevious: 0.0
        )

        XCTAssertFalse(measure.showsImprovement)
        XCTAssertFalse(measure.showsDecline)
        XCTAssertEqual(measure.progressStatus, .stable)
    }

    func testOutcomeMeasure_MaxScore() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            rawScore: 80.0,
            normalizedScore: 100.0
        )

        XCTAssertEqual(measure.severityLevel, .minimal)
    }

    func testOutcomeMeasure_ZeroScore() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:],
            rawScore: 0.0,
            normalizedScore: 0.0
        )

        XCTAssertEqual(measure.severityLevel, .complete)
    }

    func testOutcomeMeasure_EmptyResponses() {
        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .LEFS,
            responses: [:]
        )

        XCTAssertTrue(measure.responses.isEmpty)
        XCTAssertEqual(measure.formattedScore, "N/A")
    }

    func testOutcomeMeasure_ManyResponses() {
        var responses: [String: Int] = [:]
        for i in 1...50 {
            responses["q\(i)"] = i % 5
        }

        let measure = OutcomeMeasure(
            patientId: UUID(),
            therapistId: UUID(),
            measureType: .KOOS, // 42 questions
            responses: responses
        )

        XCTAssertEqual(measure.responses.count, 50)
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class OutcomeMeasureSampleDataTests: XCTestCase {

    func testOutcomeMeasure_SampleExists() {
        let sample = OutcomeMeasure.sample

        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.measureType, .LEFS)
        XCTAssertFalse(sample.responses.isEmpty)
        XCTAssertNotNil(sample.rawScore)
        XCTAssertNotNil(sample.normalizedScore)
        XCTAssertNotNil(sample.interpretation)
        XCTAssertNotNil(sample.previousScore)
        XCTAssertNotNil(sample.changeFromPrevious)
        XCTAssertEqual(sample.meetsMcid, true)
    }

    func testOutcomeMeasure_DASHSampleExists() {
        let sample = OutcomeMeasure.dashSample

        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.measureType, .DASH)
        XCTAssertNotNil(sample.rawScore)
        XCTAssertNotNil(sample.interpretation)
    }
}
#endif
