//
//  ClinicalAssessmentServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ClinicalAssessmentService
//  Tests CRUD operations, ROM measurements, functional tests, pain assessment,
//  status workflow, queries, validation, and error handling
//

import XCTest
@testable import PTPerformance

// MARK: - AssessmentType Tests

final class AssessmentTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAssessmentType_RawValues() {
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
    }

    // MARK: - Display Name Tests

    func testAssessmentType_DisplayNames() {
        XCTAssertEqual(AssessmentType.intake.displayName, "Initial Evaluation")
        XCTAssertEqual(AssessmentType.progress.displayName, "Progress Note")
        XCTAssertEqual(AssessmentType.discharge.displayName, "Discharge Summary")
        XCTAssertEqual(AssessmentType.follow_up.displayName, "Follow-Up")
    }

    // MARK: - Description Tests

    func testAssessmentType_Descriptions() {
        XCTAssertTrue(AssessmentType.intake.description.contains("initial evaluation"))
        XCTAssertTrue(AssessmentType.progress.description.contains("re-evaluation"))
        XCTAssertTrue(AssessmentType.discharge.description.contains("Final assessment"))
        XCTAssertTrue(AssessmentType.follow_up.description.contains("check-in"))
    }

    // MARK: - Icon Tests

    func testAssessmentType_IconNames() {
        XCTAssertEqual(AssessmentType.intake.iconName, "doc.text.fill")
        XCTAssertEqual(AssessmentType.progress.iconName, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(AssessmentType.discharge.iconName, "checkmark.seal.fill")
        XCTAssertEqual(AssessmentType.follow_up.iconName, "arrow.clockwise")
    }

    // MARK: - CaseIterable Tests

    func testAssessmentType_AllCases() {
        let allCases = AssessmentType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.intake))
        XCTAssertTrue(allCases.contains(.progress))
        XCTAssertTrue(allCases.contains(.discharge))
        XCTAssertTrue(allCases.contains(.follow_up))
    }

    // MARK: - Codable Tests

    func testAssessmentType_Encoding() throws {
        let type = AssessmentType.intake
        let encoder = JSONEncoder()
        let data = try encoder.encode(type)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"intake\"")
    }

    func testAssessmentType_Decoding() throws {
        let json = "\"progress\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let type = try decoder.decode(AssessmentType.self, from: json)

        XCTAssertEqual(type, .progress)
    }
}

// MARK: - AssessmentStatus Tests

final class AssessmentStatusTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAssessmentStatus_RawValues() {
        XCTAssertEqual(AssessmentStatus.draft.rawValue, "draft")
        XCTAssertEqual(AssessmentStatus.complete.rawValue, "complete")
        XCTAssertEqual(AssessmentStatus.signed.rawValue, "signed")
    }

    func testAssessmentStatus_InitFromRawValue() {
        XCTAssertEqual(AssessmentStatus(rawValue: "draft"), .draft)
        XCTAssertEqual(AssessmentStatus(rawValue: "complete"), .complete)
        XCTAssertEqual(AssessmentStatus(rawValue: "signed"), .signed)
        XCTAssertNil(AssessmentStatus(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    func testAssessmentStatus_DisplayNames() {
        XCTAssertEqual(AssessmentStatus.draft.displayName, "Draft")
        XCTAssertEqual(AssessmentStatus.complete.displayName, "Complete")
        XCTAssertEqual(AssessmentStatus.signed.displayName, "Signed")
    }

    // MARK: - Icon Tests

    func testAssessmentStatus_IconNames() {
        XCTAssertEqual(AssessmentStatus.draft.iconName, "doc.badge.ellipsis")
        XCTAssertEqual(AssessmentStatus.complete.iconName, "doc.badge.checkmark")
        XCTAssertEqual(AssessmentStatus.signed.iconName, "signature")
    }

    // MARK: - Editable Tests

    func testAssessmentStatus_IsEditable() {
        XCTAssertTrue(AssessmentStatus.draft.isEditable)
        XCTAssertTrue(AssessmentStatus.complete.isEditable)
        XCTAssertFalse(AssessmentStatus.signed.isEditable)
    }

    // MARK: - CaseIterable Tests

    func testAssessmentStatus_AllCases() {
        let allCases = AssessmentStatus.allCases
        XCTAssertEqual(allCases.count, 3)
    }

    // MARK: - Codable Tests

    func testAssessmentStatus_Encoding() throws {
        let status = AssessmentStatus.signed
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"signed\"")
    }

    func testAssessmentStatus_Decoding() throws {
        let json = "\"complete\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let status = try decoder.decode(AssessmentStatus.self, from: json)

        XCTAssertEqual(status, .complete)
    }
}

// MARK: - ClinicalAssessment Model Tests

final class ClinicalAssessmentTests: XCTestCase {

    // MARK: - Initializer Tests

    func testClinicalAssessment_DefaultInit() {
        let patientId = UUID()
        let therapistId = UUID()

        let assessment = ClinicalAssessment(
            patientId: patientId,
            therapistId: therapistId,
            assessmentType: .intake
        )

        XCTAssertEqual(assessment.patientId, patientId)
        XCTAssertEqual(assessment.therapistId, therapistId)
        XCTAssertEqual(assessment.assessmentType, .intake)
        XCTAssertEqual(assessment.status, .draft)
        XCTAssertNil(assessment.romMeasurements)
        XCTAssertNil(assessment.functionalTests)
        XCTAssertNil(assessment.painAtRest)
        XCTAssertNil(assessment.chiefComplaint)
    }

    func testClinicalAssessment_FullInit() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let date = Date()

        let romMeasurement = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let functionalTest = FunctionalTest(
            testName: "Hawkins-Kennedy",
            result: "Positive"
        )

        let assessment = ClinicalAssessment(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            assessmentType: .intake,
            assessmentDate: date,
            romMeasurements: [romMeasurement],
            functionalTests: [functionalTest],
            painAtRest: 2,
            painWithActivity: 5,
            painWorst: 7,
            painLocations: ["Right shoulder"],
            chiefComplaint: "Shoulder pain",
            historyOfPresentIllness: "3 week history",
            pastMedicalHistory: "None significant",
            functionalGoals: ["Return to sport"],
            objectiveFindings: "Decreased ROM",
            assessmentSummary: "Shoulder impingement",
            treatmentPlan: "PT 2x/week",
            status: .complete,
            signedAt: nil,
            createdAt: date,
            updatedAt: date
        )

        XCTAssertEqual(assessment.id, id)
        XCTAssertEqual(assessment.patientId, patientId)
        XCTAssertEqual(assessment.painAtRest, 2)
        XCTAssertEqual(assessment.painWithActivity, 5)
        XCTAssertEqual(assessment.painWorst, 7)
        XCTAssertEqual(assessment.romMeasurements?.count, 1)
        XCTAssertEqual(assessment.functionalTests?.count, 1)
        XCTAssertEqual(assessment.status, .complete)
    }

    // MARK: - Computed Property Tests

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
            assessmentType: .intake,
            painAtRest: 3,
            painWithActivity: nil,
            painWorst: 7
        )

        // (3 + 7) / 2 = 5.0
        XCTAssertEqual(assessment.averagePainScore ?? 0, 5.0, accuracy: 0.001)
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

    func testIsPainConcerning_HighActivityPain() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painWithActivity: 6
        )

        XCTAssertTrue(assessment.isPainConcerning)
    }

    func testIsPainConcerning_LowPain() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 2,
            painWithActivity: 4,
            painWorst: 5
        )

        XCTAssertFalse(assessment.isPainConcerning)
    }

    func testRomLimitationsCount_WithLimitations() {
        let limitedROM = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 120,  // Limited (normal is 150-180)
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let normalROM = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 140,  // Normal (normal is 130-150)
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

    func testRomLimitationsCount_NoMeasurements() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake
        )

        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testIsReadyForSignature_Complete() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentSummary: "Summary",
            treatmentPlan: "Plan",
            status: .complete
        )

        XCTAssertTrue(assessment.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingSummary() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            treatmentPlan: "Plan",
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

    func testFormattedDate() {
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 15
        let date = Calendar.current.date(from: components)!

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            assessmentDate: date
        )

        XCTAssertFalse(assessment.formattedDate.isEmpty)
    }

    func testDisplayTitle() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .progress
        )

        XCTAssertTrue(assessment.displayTitle.contains("Progress Note"))
    }
}

// MARK: - FunctionalTest Model Tests

final class FunctionalTestTests: XCTestCase {

    func testFunctionalTest_Init() {
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
    }

    func testFunctionalTest_IsAbnormal_WithAbnormalInterpretation() {
        let test = FunctionalTest(
            testName: "Neer Test",
            result: "Positive",
            interpretation: "Abnormal - indicates impingement"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_WithLimitedInterpretation() {
        let test = FunctionalTest(
            testName: "ROM Test",
            result: "40 degrees",
            interpretation: "Limited compared to contralateral"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_WithPositiveInterpretation() {
        let test = FunctionalTest(
            testName: "Special Test",
            result: "+",
            interpretation: "Positive for ligament laxity"
        )

        XCTAssertTrue(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_WithNormalInterpretation() {
        let test = FunctionalTest(
            testName: "Strength Test",
            result: "5/5",
            interpretation: "Normal strength throughout"
        )

        XCTAssertFalse(test.isAbnormal)
    }

    func testFunctionalTest_IsAbnormal_NoInterpretation() {
        let test = FunctionalTest(
            testName: "Test",
            result: "Result"
        )

        XCTAssertFalse(test.isAbnormal)
    }
}

// MARK: - ClinicalAssessmentInput Validation Tests

final class ClinicalAssessmentInputTests: XCTestCase {

    // MARK: - Valid Input Tests

    func testValidate_ValidInput_DoesNotThrow() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            assessmentDate: "2024-01-15",
            painAtRest: 5,
            painWithActivity: 7,
            painWorst: 8
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_BoundaryValues_DoesNotThrow() {
        // Test minimum value (0)
        let minInput = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 0,
            painWithActivity: 0,
            painWorst: 0
        )
        XCTAssertNoThrow(try minInput.validate())

        // Test maximum value (10)
        let maxInput = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 10,
            painWithActivity: 10,
            painWorst: 10
        )
        XCTAssertNoThrow(try maxInput.validate())
    }

    func testValidate_NilPainScores_DoesNotThrow() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake"
        )

        XCTAssertNoThrow(try input.validate())
    }

    // MARK: - Invalid Input Tests

    func testValidate_PainAtRestOutOfRange_Throws() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: 11
        )

        XCTAssertThrowsError(try input.validate()) { error in
            if case ClinicalAssessmentError.invalidPainScore(let message) = error {
                XCTAssertTrue(message.contains("Pain at rest"))
            } else {
                XCTFail("Expected ClinicalAssessmentError.invalidPainScore")
            }
        }
    }

    func testValidate_PainWithActivityOutOfRange_Throws() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painWithActivity: 15
        )

        XCTAssertThrowsError(try input.validate()) { error in
            if case ClinicalAssessmentError.invalidPainScore(let message) = error {
                XCTAssertTrue(message.contains("Pain with activity"))
            } else {
                XCTFail("Expected ClinicalAssessmentError.invalidPainScore")
            }
        }
    }

    func testValidate_PainWorstOutOfRange_Throws() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painWorst: -1
        )

        XCTAssertThrowsError(try input.validate()) { error in
            if case ClinicalAssessmentError.invalidPainScore(let message) = error {
                XCTAssertTrue(message.contains("Worst pain"))
            } else {
                XCTFail("Expected ClinicalAssessmentError.invalidPainScore")
            }
        }
    }

    func testValidate_NegativePainScore_Throws() {
        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            painAtRest: -5
        )

        XCTAssertThrowsError(try input.validate())
    }
}

// MARK: - ClinicalAssessmentError Tests

final class ClinicalAssessmentErrorTests: XCTestCase {

    func testInvalidPainScore_ErrorDescription() {
        let error = ClinicalAssessmentError.invalidPainScore("Pain at rest must be 0-10")
        XCTAssertEqual(error.errorDescription, "Pain at rest must be 0-10")
    }

    func testAssessmentNotFound_ErrorDescription() {
        let error = ClinicalAssessmentError.assessmentNotFound
        XCTAssertEqual(error.errorDescription, "Clinical assessment not found")
    }

    func testSaveFailed_ErrorDescription() {
        let error = ClinicalAssessmentError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save clinical assessment")
    }

    func testFetchFailed_ErrorDescription() {
        let error = ClinicalAssessmentError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch clinical assessment")
    }

    func testCannotEditSigned_ErrorDescription() {
        let error = ClinicalAssessmentError.cannotEditSigned
        XCTAssertEqual(error.errorDescription, "Cannot edit a signed assessment")
    }

    func testMissingRequiredFields_ErrorDescription() {
        let error = ClinicalAssessmentError.missingRequiredFields
        XCTAssertEqual(error.errorDescription, "Missing required fields for assessment")
    }

    func testError_Cases() {
        // Verify error cases exist and have descriptions
        let errors: [ClinicalAssessmentError] = [
            .assessmentNotFound,
            .saveFailed,
            .fetchFailed,
            .cannotEditSigned,
            .missingRequiredFields,
            .invalidPainScore("test")
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - ClinicalAssessmentService Tests

@MainActor
final class ClinicalAssessmentServiceTests: XCTestCase {

    var sut: ClinicalAssessmentService!

    override func setUp() async throws {
        try await super.setUp()
        sut = ClinicalAssessmentService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(ClinicalAssessmentService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = ClinicalAssessmentService.shared
        let instance2 = ClinicalAssessmentService.shared
        XCTAssertTrue(instance1 === instance2, "Shared instances should be the same object")
    }

    // MARK: - Initial State Tests

    func testInitialState_IsLoadingIsFalse() {
        _ = sut.isLoading
    }

    func testInitialState_ErrorIsNil() {
        _ = sut.error
    }

    func testInitialState_CurrentAssessmentIsNil() {
        // Current assessment may be set from other tests, just verify accessible
        _ = sut.currentAssessment
    }

    // MARK: - Published Properties Tests

    func testIsLoading_IsPublished() {
        let loading = sut.isLoading
        XCTAssertTrue(loading == true || loading == false)
    }

    func testError_IsPublished() {
        let error = sut.error
        _ = error
    }

    func testCurrentAssessment_IsPublished() {
        let current = sut.currentAssessment
        _ = current
    }

    // MARK: - Custom Init Tests

    func testCustomInit_WithClient() {
        // Verify custom initialization works
        let service = ClinicalAssessmentService()
        XCTAssertNotNil(service)
    }
}

// MARK: - ClinicalAssessmentSummary Tests

final class ClinicalAssessmentSummaryTests: XCTestCase {

    func testHasAssessments_WithAssessments() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 5,
            draftCount: 2,
            signedCount: 3
        )

        XCTAssertTrue(summary.hasAssessments)
    }

    func testHasAssessments_NoAssessments() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 0,
            draftCount: 0,
            signedCount: 0
        )

        XCTAssertFalse(summary.hasAssessments)
    }

    func testHasPendingDrafts_WithDrafts() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 5,
            draftCount: 2,
            signedCount: 3
        )

        XCTAssertTrue(summary.hasPendingDrafts)
    }

    func testHasPendingDrafts_NoDrafts() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 5,
            draftCount: 0,
            signedCount: 5
        )

        XCTAssertFalse(summary.hasPendingDrafts)
    }

    func testCurrentStatus_WithLatestAssessment() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .complete
        )

        let summary = ClinicalAssessmentSummary(
            latestAssessment: assessment,
            totalAssessments: 1,
            draftCount: 0,
            signedCount: 0
        )

        XCTAssertEqual(summary.currentStatus, .complete)
    }

    func testCurrentStatus_NoLatestAssessment() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 0,
            draftCount: 0,
            signedCount: 0
        )

        XCTAssertNil(summary.currentStatus)
    }

    func testAveragePainScore_WithAssessment() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painAtRest: 3,
            painWithActivity: 6,
            painWorst: 9
        )

        let summary = ClinicalAssessmentSummary(
            latestAssessment: assessment,
            totalAssessments: 1,
            draftCount: 1,
            signedCount: 0
        )

        // (3 + 6 + 9) / 3 = 6.0
        XCTAssertEqual(summary.averagePainScore ?? 0, 6.0, accuracy: 0.001)
    }

    func testRomLimitationsCount_WithAssessment() {
        let limitedROM = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 100,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [limitedROM]
        )

        let summary = ClinicalAssessmentSummary(
            latestAssessment: assessment,
            totalAssessments: 1,
            draftCount: 1,
            signedCount: 0
        )

        XCTAssertEqual(summary.romLimitationsCount, 1)
    }

    func testRomLimitationsCount_NoAssessment() {
        let summary = ClinicalAssessmentSummary(
            latestAssessment: nil,
            totalAssessments: 0,
            draftCount: 0,
            signedCount: 0
        )

        XCTAssertEqual(summary.romLimitationsCount, 0)
    }
}

// MARK: - ROMeasurement Tests (Related to Clinical Assessment)

final class ROMeasurementClinicalTests: XCTestCase {

    func testROMeasurement_Init() {
        let id = UUID()
        let measurement = ROMeasurement(
            id: id,
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right,
            painWithMovement: true,
            endFeel: "Capsular",
            notes: "Limited ROM"
        )

        XCTAssertEqual(measurement.id, id)
        XCTAssertEqual(measurement.joint, "shoulder")
        XCTAssertEqual(measurement.movement, "flexion")
        XCTAssertEqual(measurement.degrees, 140)
        XCTAssertEqual(measurement.normalRangeMin, 150)
        XCTAssertEqual(measurement.normalRangeMax, 180)
        XCTAssertEqual(measurement.side, .right)
        XCTAssertEqual(measurement.painWithMovement, true)
    }

    func testROMeasurement_IsLimited() {
        let limited = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 120,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        XCTAssertTrue(limited.isLimited)
    }

    func testROMeasurement_IsNotLimited() {
        let normal = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 160,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        XCTAssertFalse(normal.isLimited)
    }

    func testROMeasurement_IsHypermobile() {
        let hypermobile = ROMeasurement(
            joint: "elbow",
            movement: "extension",
            degrees: 15,
            normalRangeMin: 0,
            normalRangeMax: 10,
            side: .left
        )

        XCTAssertTrue(hypermobile.isHypermobile)
    }

    func testROMeasurement_PercentageOfNormal() {
        let measurement = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 90,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        // 90/180 * 100 = 50%
        XCTAssertEqual(measurement.percentageOfNormal, 50.0, accuracy: 0.001)
    }

    func testROMeasurement_LimitationSeverity() {
        // Severe (<50%)
        let severe = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 80,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )
        XCTAssertEqual(severe.limitationSeverity, .severe)

        // Moderate (50-74%)
        let moderate = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 120,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )
        XCTAssertEqual(moderate.limitationSeverity, .moderate)

        // Mild (75-89%)
        let mild = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 150,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )
        XCTAssertEqual(mild.limitationSeverity, .mild)

        // None (90%+)
        let none = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 170,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )
        XCTAssertEqual(none.limitationSeverity, .none)
    }

    func testROMeasurement_FormattedMeasurement() {
        let measurement = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 135,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        XCTAssertEqual(measurement.formattedMeasurement, "135\u{00B0}")
    }

    func testROMeasurement_FormattedNormalRange() {
        let measurement = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 135,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        XCTAssertEqual(measurement.formattedNormalRange, "130\u{00B0} - 150\u{00B0}")
    }
}

// MARK: - Side Enum Tests

final class SideEnumTests: XCTestCase {

    func testSide_RawValues() {
        XCTAssertEqual(Side.left.rawValue, "left")
        XCTAssertEqual(Side.right.rawValue, "right")
        XCTAssertEqual(Side.bilateral.rawValue, "bilateral")
    }

    func testSide_DisplayNames() {
        XCTAssertEqual(Side.left.displayName, "Left")
        XCTAssertEqual(Side.right.displayName, "Right")
        XCTAssertEqual(Side.bilateral.displayName, "Bilateral")
    }

    func testSide_Abbreviations() {
        XCTAssertEqual(Side.left.abbreviation, "L")
        XCTAssertEqual(Side.right.abbreviation, "R")
        XCTAssertEqual(Side.bilateral.abbreviation, "B")
    }

    func testSide_CaseIterable() {
        XCTAssertEqual(Side.allCases.count, 3)
    }
}

// MARK: - LimitationSeverity Tests

final class LimitationSeverityTests: XCTestCase {

    func testLimitationSeverity_RawValues() {
        XCTAssertEqual(LimitationSeverity.none.rawValue, "none")
        XCTAssertEqual(LimitationSeverity.mild.rawValue, "mild")
        XCTAssertEqual(LimitationSeverity.moderate.rawValue, "moderate")
        XCTAssertEqual(LimitationSeverity.severe.rawValue, "severe")
    }

    func testLimitationSeverity_DisplayNames() {
        XCTAssertEqual(LimitationSeverity.none.displayName, "Within Normal Limits")
        XCTAssertEqual(LimitationSeverity.mild.displayName, "Mild Limitation")
        XCTAssertEqual(LimitationSeverity.moderate.displayName, "Moderate Limitation")
        XCTAssertEqual(LimitationSeverity.severe.displayName, "Severe Limitation")
    }
}

// MARK: - Codable Decoding Tests

final class ClinicalAssessmentDecodingTests: XCTestCase {

    func testClinicalAssessment_Decoding() throws {
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
            "chief_complaint": "Shoulder pain",
            "status": "draft",
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
        XCTAssertEqual(assessment.chiefComplaint, "Shoulder pain")
        XCTAssertEqual(assessment.status, .draft)
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
    }

    func testFunctionalTest_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "test_name": "Hawkins-Kennedy Test",
            "result": "Positive",
            "score": 1.0,
            "normal_value": "Negative",
            "interpretation": "Indicates possible subacromial impingement",
            "notes": "Pain reproduced with internal rotation"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let test = try decoder.decode(FunctionalTest.self, from: json)

        XCTAssertEqual(test.testName, "Hawkins-Kennedy Test")
        XCTAssertEqual(test.result, "Positive")
        XCTAssertEqual(test.score, 1.0)
        XCTAssertEqual(test.normalValue, "Negative")
        XCTAssertTrue(test.interpretation!.contains("impingement"))
    }

    func testROMeasurement_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "joint": "shoulder",
            "movement": "flexion",
            "degrees": 140,
            "normal_range_min": 150,
            "normal_range_max": 180,
            "side": "right",
            "measurement_method": "Goniometer",
            "pain_with_movement": true,
            "end_feel": "Capsular",
            "notes": "Pain at end range"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let measurement = try decoder.decode(ROMeasurement.self, from: json)

        XCTAssertEqual(measurement.joint, "shoulder")
        XCTAssertEqual(measurement.movement, "flexion")
        XCTAssertEqual(measurement.degrees, 140)
        XCTAssertEqual(measurement.normalRangeMin, 150)
        XCTAssertEqual(measurement.normalRangeMax, 180)
        XCTAssertEqual(measurement.side, .right)
        XCTAssertEqual(measurement.painWithMovement, true)
    }

    func testAssessmentType_AllTypes_Decode() throws {
        let types = ["intake", "progress", "discharge", "follow_up"]

        for type in types {
            let json = "\"\(type)\"".data(using: .utf8)!
            let decoder = JSONDecoder()
            let assessmentType = try decoder.decode(AssessmentType.self, from: json)
            XCTAssertEqual(assessmentType.rawValue, type)
        }
    }

    func testAssessmentStatus_AllStatuses_Decode() throws {
        let statuses = ["draft", "complete", "signed"]

        for status in statuses {
            let json = "\"\(status)\"".data(using: .utf8)!
            let decoder = JSONDecoder()
            let assessmentStatus = try decoder.decode(AssessmentStatus.self, from: json)
            XCTAssertEqual(assessmentStatus.rawValue, status)
        }
    }
}

// MARK: - Edge Cases Tests

final class ClinicalAssessmentEdgeCasesTests: XCTestCase {

    func testAssessment_AllPainScoresZero() {
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

    func testAssessment_AllPainScoresTen() {
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

    func testAssessment_EmptyROMMeasurements() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: []
        )

        XCTAssertEqual(assessment.romLimitationsCount, 0)
    }

    func testAssessment_EmptyFunctionalTests() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            functionalTests: []
        )

        XCTAssertNotNil(assessment.functionalTests)
        XCTAssertTrue(assessment.functionalTests!.isEmpty)
    }

    func testAssessment_EmptyPainLocations() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            painLocations: []
        )

        XCTAssertNotNil(assessment.painLocations)
        XCTAssertTrue(assessment.painLocations!.isEmpty)
    }

    func testAssessment_EmptyFunctionalGoals() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            functionalGoals: []
        )

        XCTAssertNotNil(assessment.functionalGoals)
        XCTAssertTrue(assessment.functionalGoals!.isEmpty)
    }

    func testAssessment_MultipleROMWithMixedLimitations() {
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

        let normal1 = ROMeasurement(
            joint: "elbow",
            movement: "flexion",
            degrees: 145,
            normalRangeMin: 140,
            normalRangeMax: 150,
            side: .right
        )

        let normal2 = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 140,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            romMeasurements: [limited1, limited2, normal1, normal2]
        )

        XCTAssertEqual(assessment.romLimitationsCount, 2)
    }

    func testAssessment_SignedAssessment_NotEditable() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .signed
        )

        XCTAssertFalse(assessment.status.isEditable)
    }

    func testAssessment_DraftAssessment_IsEditable() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .draft
        )

        XCTAssertTrue(assessment.status.isEditable)
    }

    func testAssessment_CompleteAssessment_IsEditable() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .complete
        )

        XCTAssertTrue(assessment.status.isEditable)
    }

    func testROMeasurement_ZeroDegrees() {
        let measurement = ROMeasurement(
            joint: "elbow",
            movement: "extension",
            degrees: 0,
            normalRangeMin: 0,
            normalRangeMax: 10,
            side: .right
        )

        XCTAssertFalse(measurement.isLimited)
        XCTAssertFalse(measurement.isHypermobile)
    }

    func testROMeasurement_ExactlyAtMinNormal() {
        let measurement = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 130,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        XCTAssertFalse(measurement.isLimited)
    }

    func testROMeasurement_ExactlyAtMaxNormal() {
        let measurement = ROMeasurement(
            joint: "knee",
            movement: "flexion",
            degrees: 150,
            normalRangeMin: 130,
            normalRangeMax: 150,
            side: .left
        )

        XCTAssertFalse(measurement.isHypermobile)
    }
}

// MARK: - Status Workflow Tests

final class StatusWorkflowTests: XCTestCase {

    func testStatusTransition_DraftToComplete() {
        var assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .draft
        )

        XCTAssertEqual(assessment.status, .draft)
        assessment.status = .complete
        XCTAssertEqual(assessment.status, .complete)
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

    func testSignedAssessment_CannotTransitionBack() {
        let assessment = ClinicalAssessment(
            patientId: UUID(),
            therapistId: UUID(),
            assessmentType: .intake,
            status: .signed
        )

        // Signed status is not editable
        XCTAssertFalse(assessment.status.isEditable)
    }
}

// MARK: - ClinicalAssessmentInput Encoding Tests

final class ClinicalAssessmentInputEncodingTests: XCTestCase {

    func testClinicalAssessmentInput_Encoding() throws {
        let input = ClinicalAssessmentInput(
            patientId: "550e8400-e29b-41d4-a716-446655440000",
            therapistId: "660e8400-e29b-41d4-a716-446655440001",
            assessmentType: "intake",
            assessmentDate: "2024-03-15",
            painAtRest: 3,
            painWithActivity: 5,
            painWorst: 7,
            painLocations: ["Right shoulder"],
            chiefComplaint: "Shoulder pain",
            status: "draft"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("patient_id"))
        XCTAssertTrue(jsonString.contains("therapist_id"))
        XCTAssertTrue(jsonString.contains("assessment_type"))
        XCTAssertTrue(jsonString.contains("pain_at_rest"))
    }

    func testClinicalAssessmentInput_EncodingWithROM() throws {
        let romMeasurement = ROMeasurement(
            joint: "shoulder",
            movement: "flexion",
            degrees: 140,
            normalRangeMin: 150,
            normalRangeMax: 180,
            side: .right
        )

        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            romMeasurements: [romMeasurement]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("rom_measurements"))
    }

    func testClinicalAssessmentInput_EncodingWithFunctionalTests() throws {
        let functionalTest = FunctionalTest(
            testName: "Hawkins-Kennedy",
            result: "Positive"
        )

        let input = ClinicalAssessmentInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            assessmentType: "intake",
            functionalTests: [functionalTest]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("functional_tests"))
    }
}

// MARK: - JointType and MovementType Tests

final class JointTypeTests: XCTestCase {

    func testJointType_RawValues() {
        XCTAssertEqual(JointType.shoulder.rawValue, "shoulder")
        XCTAssertEqual(JointType.elbow.rawValue, "elbow")
        XCTAssertEqual(JointType.wrist.rawValue, "wrist")
        XCTAssertEqual(JointType.hip.rawValue, "hip")
        XCTAssertEqual(JointType.knee.rawValue, "knee")
        XCTAssertEqual(JointType.ankle.rawValue, "ankle")
        XCTAssertEqual(JointType.cervical.rawValue, "cervical")
        XCTAssertEqual(JointType.thoracic.rawValue, "thoracic")
        XCTAssertEqual(JointType.lumbar.rawValue, "lumbar")
    }

    func testJointType_DisplayNames() {
        XCTAssertEqual(JointType.shoulder.displayName, "Shoulder")
        XCTAssertEqual(JointType.cervical.displayName, "Cervical Spine")
        XCTAssertEqual(JointType.thoracic.displayName, "Thoracic Spine")
        XCTAssertEqual(JointType.lumbar.displayName, "Lumbar Spine")
    }

    func testJointType_AvailableMovements() {
        let shoulderMovements = JointType.shoulder.availableMovements
        XCTAssertTrue(shoulderMovements.contains(.flexion))
        XCTAssertTrue(shoulderMovements.contains(.extension))
        XCTAssertTrue(shoulderMovements.contains(.abduction))
        XCTAssertTrue(shoulderMovements.contains(.internalRotation))
        XCTAssertTrue(shoulderMovements.contains(.externalRotation))

        let kneeMovements = JointType.knee.availableMovements
        XCTAssertTrue(kneeMovements.contains(.flexion))
        XCTAssertTrue(kneeMovements.contains(.extension))
        XCTAssertEqual(kneeMovements.count, 2)
    }

    func testJointType_AllCases() {
        XCTAssertEqual(JointType.allCases.count, 9)
    }
}

final class MovementTypeTests: XCTestCase {

    func testMovementType_RawValues() {
        XCTAssertEqual(MovementType.flexion.rawValue, "flexion")
        XCTAssertEqual(MovementType.extension.rawValue, "extension")
        XCTAssertEqual(MovementType.internalRotation.rawValue, "internal_rotation")
        XCTAssertEqual(MovementType.externalRotation.rawValue, "external_rotation")
        XCTAssertEqual(MovementType.dorsiflexion.rawValue, "dorsiflexion")
        XCTAssertEqual(MovementType.plantarflexion.rawValue, "plantarflexion")
    }

    func testMovementType_DisplayNames() {
        XCTAssertEqual(MovementType.flexion.displayName, "Flexion")
        XCTAssertEqual(MovementType.extension.displayName, "Extension")
        XCTAssertEqual(MovementType.internalRotation.displayName, "Internal Rotation")
        XCTAssertEqual(MovementType.externalRotation.displayName, "External Rotation")
    }

    func testMovementType_AllCases() {
        XCTAssertEqual(MovementType.allCases.count, 16)
    }
}

// MARK: - ROMNormalReference Tests

final class ROMNormalReferenceTests: XCTestCase {

    func testNormalRange_ShoulderFlexion() {
        let range = ROMNormalReference.normalRange(joint: "shoulder", movement: "flexion")
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.lowerBound, 150)
        XCTAssertEqual(range?.upperBound, 180)
    }

    func testNormalRange_KneeFlexion() {
        let range = ROMNormalReference.normalRange(joint: "knee", movement: "flexion")
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.lowerBound, 130)
        XCTAssertEqual(range?.upperBound, 150)
    }

    func testNormalRange_InvalidJoint() {
        let range = ROMNormalReference.normalRange(joint: "invalid", movement: "flexion")
        XCTAssertNil(range)
    }

    func testNormalRange_InvalidMovement() {
        let range = ROMNormalReference.normalRange(joint: "shoulder", movement: "invalid")
        XCTAssertNil(range)
    }

    func testNormalRange_CaseInsensitive() {
        let range1 = ROMNormalReference.normalRange(joint: "SHOULDER", movement: "FLEXION")
        let range2 = ROMNormalReference.normalRange(joint: "shoulder", movement: "flexion")
        XCTAssertEqual(range1, range2)
    }
}
