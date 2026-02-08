//
//  ClinicalAssessmentTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for clinical assessment functionality
//  Tests SOAP note creation, assessment signing workflow, and clinical data validation
//

import XCTest
@testable import PTPerformance

// MARK: - SOAP Note Creation Tests

final class SOAPNoteCreationTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testSOAPNote_MinimalInit() {
        let patientId = UUID()
        let therapistId = UUID()

        let note = SOAPNote(
            patientId: patientId,
            therapistId: therapistId
        )

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.patientId, patientId)
        XCTAssertEqual(note.therapistId, therapistId)
        XCTAssertEqual(note.status, .draft)
    }

    func testSOAPNote_FullInit() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let sessionId = UUID()
        let noteDate = Date()
        let vitals = Vitals(bloodPressure: "120/80", heartRate: 72)

        let note = SOAPNote(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            sessionId: sessionId,
            noteDate: noteDate,
            subjective: "Patient reports improvement",
            objective: "ROM increased",
            assessment: "Progressing well",
            plan: "Continue treatment",
            vitals: vitals,
            painLevel: 3,
            functionalStatus: .improving,
            timeSpentMinutes: 45,
            cptCodes: ["97110", "97140"],
            status: .complete
        )

        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.patientId, patientId)
        XCTAssertEqual(note.therapistId, therapistId)
        XCTAssertEqual(note.sessionId, sessionId)
        XCTAssertEqual(note.subjective, "Patient reports improvement")
        XCTAssertEqual(note.objective, "ROM increased")
        XCTAssertEqual(note.assessment, "Progressing well")
        XCTAssertEqual(note.plan, "Continue treatment")
        XCTAssertEqual(note.painLevel, 3)
        XCTAssertEqual(note.functionalStatus, .improving)
        XCTAssertEqual(note.timeSpentMinutes, 45)
        XCTAssertEqual(note.cptCodes?.count, 2)
        XCTAssertEqual(note.status, .complete)
    }

    // MARK: - SOAP Section Tests

    func testSOAPNote_SubjectiveSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Patient reports decreased pain levels since last visit"
        )

        XCTAssertEqual(note.subjective, "Patient reports decreased pain levels since last visit")
    }

    func testSOAPNote_ObjectiveSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            objective: "ROM: Shoulder flexion 160 degrees, abduction 150 degrees"
        )

        XCTAssertEqual(note.objective, "ROM: Shoulder flexion 160 degrees, abduction 150 degrees")
    }

    func testSOAPNote_AssessmentSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            assessment: "Patient demonstrating steady improvement in functional mobility"
        )

        XCTAssertEqual(note.assessment, "Patient demonstrating steady improvement in functional mobility")
    }

    func testSOAPNote_PlanSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            plan: "Continue current exercise program. Progress to phase 2 next week."
        )

        XCTAssertEqual(note.plan, "Continue current exercise program. Progress to phase 2 next week.")
    }

    // MARK: - Completeness Tests

    func testCompletenessPercentage_Empty() {
        let note = SOAPNote(patientId: UUID(), therapistId: UUID())

        XCTAssertEqual(note.completenessPercentage, 0.0)
    }

    func testCompletenessPercentage_OneSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Some content"
        )

        XCTAssertEqual(note.completenessPercentage, 25.0)
    }

    func testCompletenessPercentage_TwoSections() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Content",
            objective: "Content"
        )

        XCTAssertEqual(note.completenessPercentage, 50.0)
    }

    func testCompletenessPercentage_ThreeSections() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Content",
            objective: "Content",
            assessment: "Content"
        )

        XCTAssertEqual(note.completenessPercentage, 75.0)
    }

    func testCompletenessPercentage_AllSections() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P"
        )

        XCTAssertEqual(note.completenessPercentage, 100.0)
    }

    func testCompletenessPercentage_EmptyStringsIgnored() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "",
            objective: "",
            assessment: "",
            plan: ""
        )

        XCTAssertEqual(note.completenessPercentage, 0.0)
    }

    // MARK: - Preview Text Tests

    func testPreviewText_WithContent() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Patient reports feeling better"
        )

        XCTAssertEqual(note.previewText, "Patient reports feeling better")
    }

    func testPreviewText_Empty() {
        let note = SOAPNote(patientId: UUID(), therapistId: UUID())

        XCTAssertEqual(note.previewText, "No content")
    }

    func testPreviewText_TruncatesLongContent() {
        let longContent = String(repeating: "A", count: 200)
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: longContent
        )

        XCTAssertTrue(note.previewText.hasSuffix("..."))
        XCTAssertLessThanOrEqual(note.previewText.count, 103)
    }
}

// MARK: - Assessment Signing Workflow Tests

final class AssessmentSigningWorkflowTests: XCTestCase {

    // MARK: - Ready For Signature Tests

    func testIsReadyForSignature_CompleteNote() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .complete
        )

        XCTAssertTrue(note.isReadyForSignature)
    }

    func testIsReadyForSignature_DraftStatus() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .draft
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingSubjective() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: nil,
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .complete
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingObjective() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: nil,
            assessment: "A",
            plan: "P",
            status: .complete
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingAssessment() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: nil,
            plan: "P",
            status: .complete
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    func testIsReadyForSignature_MissingPlan() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: nil,
            status: .complete
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    func testIsReadyForSignature_EmptyStringsNotReady() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "",
            objective: "",
            assessment: "",
            plan: "",
            status: .complete
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    // MARK: - Status Editable Tests

    func testNoteStatus_DraftIsEditable() {
        XCTAssertTrue(NoteStatus.draft.isEditable)
    }

    func testNoteStatus_CompleteIsNotEditable() {
        XCTAssertFalse(NoteStatus.complete.isEditable)
    }

    func testNoteStatus_SignedIsNotEditable() {
        XCTAssertFalse(NoteStatus.signed.isEditable)
    }

    func testNoteStatus_AddendumIsEditable() {
        XCTAssertTrue(NoteStatus.addendum.isEditable)
    }

    // MARK: - Addendum Tests

    func testIsAddendum_WithParentNoteId() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            parentNoteId: UUID()
        )

        XCTAssertTrue(note.isAddendum)
    }

    func testIsAddendum_WithAddendumStatus() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            status: .addendum
        )

        XCTAssertTrue(note.isAddendum)
    }

    func testIsAddendum_RegularNote() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            status: .draft
        )

        XCTAssertFalse(note.isAddendum)
    }

    // MARK: - Signed Note Tests

    func testSignedNote_HasSignedAt() {
        let signedAt = Date()
        let note = SOAPNote(
            id: UUID(),
            patientId: UUID(),
            therapistId: UUID(),
            signedAt: signedAt,
            signedBy: "Dr. Smith, PT"
        )

        XCTAssertEqual(note.signedAt, signedAt)
        XCTAssertEqual(note.signedBy, "Dr. Smith, PT")
    }
}

// MARK: - Clinical Data Validation Tests

final class ClinicalDataValidationTests: XCTestCase {

    // MARK: - Pain Level Validation Tests

    func testSOAPNoteInput_ValidPainLevel_Zero() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 0
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testSOAPNoteInput_ValidPainLevel_Ten() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 10
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testSOAPNoteInput_ValidPainLevel_Middle() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 5
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testSOAPNoteInput_InvalidPainLevel_Negative() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: -1
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertTrue(error is SOAPNoteError)
        }
    }

    func testSOAPNoteInput_InvalidPainLevel_TooHigh() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 11
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertTrue(error is SOAPNoteError)
        }
    }

    // MARK: - Time Spent Validation Tests

    func testSOAPNoteInput_ValidTimeSpent() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            timeSpentMinutes: 45
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testSOAPNoteInput_ZeroTimeSpent() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            timeSpentMinutes: 0
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testSOAPNoteInput_NegativeTimeSpent() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            timeSpentMinutes: -10
        )

        XCTAssertThrowsError(try input.validate()) { error in
            XCTAssertTrue(error is SOAPNoteError)
        }
    }

    // MARK: - Update Validation Tests

    func testSOAPNoteUpdate_ValidPainLevel() throws {
        let update = SOAPNoteUpdate(painLevel: 5)

        XCTAssertNoThrow(try update.validate())
    }

    func testSOAPNoteUpdate_InvalidPainLevel() {
        let update = SOAPNoteUpdate(painLevel: 15)

        XCTAssertThrowsError(try update.validate())
    }

    func testSOAPNoteUpdate_InvalidTimeSpent() {
        let update = SOAPNoteUpdate(timeSpentMinutes: -5)

        XCTAssertThrowsError(try update.validate())
    }

    func testSOAPNoteUpdate_AllValidFields() throws {
        let update = SOAPNoteUpdate(
            subjective: "Updated",
            objective: "Updated",
            assessment: "Updated",
            plan: "Updated",
            painLevel: 3,
            timeSpentMinutes: 30
        )

        XCTAssertNoThrow(try update.validate())
    }
}

// MARK: - Vitals Tests

final class VitalsValidationTests: XCTestCase {

    func testVitals_AllFields() {
        let vitals = Vitals(
            bloodPressure: "120/80",
            heartRate: 72,
            temperature: 98.6,
            respiratoryRate: 16,
            oxygenSaturation: 98,
            weight: 175.5
        )

        XCTAssertEqual(vitals.bloodPressure, "120/80")
        XCTAssertEqual(vitals.heartRate, 72)
        XCTAssertEqual(vitals.temperature, 98.6)
        XCTAssertEqual(vitals.respiratoryRate, 16)
        XCTAssertEqual(vitals.oxygenSaturation, 98)
        XCTAssertEqual(vitals.weight, 175.5)
    }

    func testVitals_HasData_True() {
        let vitals = Vitals(heartRate: 72)

        XCTAssertTrue(vitals.hasData)
    }

    func testVitals_HasData_False() {
        let vitals = Vitals()

        XCTAssertFalse(vitals.hasData)
    }

    func testVitals_Summary_WithAllFields() {
        let vitals = Vitals(
            bloodPressure: "120/80",
            heartRate: 72,
            temperature: 98.6,
            respiratoryRate: 16,
            oxygenSaturation: 98
        )

        let summary = vitals.summary
        XCTAssertTrue(summary.contains("BP: 120/80"))
        XCTAssertTrue(summary.contains("HR: 72"))
        XCTAssertTrue(summary.contains("Temp: 98.6"))
        XCTAssertTrue(summary.contains("RR: 16"))
        XCTAssertTrue(summary.contains("O2: 98%"))
    }

    func testVitals_Summary_Partial() {
        let vitals = Vitals(bloodPressure: "118/76", heartRate: 68)

        let summary = vitals.summary
        XCTAssertTrue(summary.contains("BP: 118/76"))
        XCTAssertTrue(summary.contains("HR: 68"))
        XCTAssertFalse(summary.contains("Temp"))
    }

    func testVitals_Summary_Empty() {
        let vitals = Vitals()

        XCTAssertEqual(vitals.summary, "")
    }

    func testVitals_Equatable() {
        let vitals1 = Vitals(bloodPressure: "120/80", heartRate: 72)
        let vitals2 = Vitals(bloodPressure: "120/80", heartRate: 72)

        XCTAssertEqual(vitals1, vitals2)
    }

    func testVitals_NotEqual() {
        let vitals1 = Vitals(bloodPressure: "120/80")
        let vitals2 = Vitals(bloodPressure: "130/85")

        XCTAssertNotEqual(vitals1, vitals2)
    }
}

// MARK: - Formatted Output Tests

final class SOAPNoteFormattedOutputTests: XCTestCase {

    func testFormattedTimeSpent_Nil() {
        let note = SOAPNote(patientId: UUID(), therapistId: UUID())

        XCTAssertNil(note.formattedTimeSpent)
    }

    func testFormattedTimeSpent_Minutes() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 45
        )

        XCTAssertEqual(note.formattedTimeSpent, "45 min")
    }

    func testFormattedTimeSpent_Hours() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 60
        )

        XCTAssertEqual(note.formattedTimeSpent, "1h")
    }

    func testFormattedTimeSpent_HoursAndMinutes() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 90
        )

        XCTAssertEqual(note.formattedTimeSpent, "1h 30m")
    }

    func testFormattedTimeSpent_MultipleHours() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 150
        )

        XCTAssertEqual(note.formattedTimeSpent, "2h 30m")
    }

    func testFormattedCptCodes_Nil() {
        let note = SOAPNote(patientId: UUID(), therapistId: UUID())

        XCTAssertNil(note.formattedCptCodes)
    }

    func testFormattedCptCodes_Empty() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: []
        )

        XCTAssertNil(note.formattedCptCodes)
    }

    func testFormattedCptCodes_Single() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: ["97110"]
        )

        XCTAssertEqual(note.formattedCptCodes, "97110")
    }

    func testFormattedCptCodes_Multiple() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: ["97110", "97140", "97530"]
        )

        XCTAssertEqual(note.formattedCptCodes, "97110, 97140, 97530")
    }
}

// MARK: - Functional Status Tests

final class FunctionalStatusValidationTests: XCTestCase {

    func testFunctionalStatus_RawValues() {
        XCTAssertEqual(FunctionalStatus.improving.rawValue, "improving")
        XCTAssertEqual(FunctionalStatus.stable.rawValue, "stable")
        XCTAssertEqual(FunctionalStatus.declining.rawValue, "declining")
    }

    func testFunctionalStatus_DisplayNames() {
        XCTAssertEqual(FunctionalStatus.improving.displayName, "Improving")
        XCTAssertEqual(FunctionalStatus.stable.displayName, "Stable")
        XCTAssertEqual(FunctionalStatus.declining.displayName, "Declining")
    }

    func testFunctionalStatus_IconNames() {
        XCTAssertEqual(FunctionalStatus.improving.iconName, "arrow.up.right")
        XCTAssertEqual(FunctionalStatus.stable.iconName, "arrow.right")
        XCTAssertEqual(FunctionalStatus.declining.iconName, "arrow.down.right")
    }

    func testFunctionalStatus_AllCases() {
        XCTAssertEqual(FunctionalStatus.allCases.count, 3)
    }

    func testFunctionalStatus_Codable() throws {
        let status = FunctionalStatus.improving

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FunctionalStatus.self, from: data)

        XCTAssertEqual(decoded, status)
    }
}

// MARK: - NoteStatus Tests

final class NoteStatusValidationTests: XCTestCase {

    func testNoteStatus_RawValues() {
        XCTAssertEqual(NoteStatus.draft.rawValue, "draft")
        XCTAssertEqual(NoteStatus.complete.rawValue, "complete")
        XCTAssertEqual(NoteStatus.signed.rawValue, "signed")
        XCTAssertEqual(NoteStatus.addendum.rawValue, "addendum")
    }

    func testNoteStatus_DisplayNames() {
        XCTAssertEqual(NoteStatus.draft.displayName, "Draft")
        XCTAssertEqual(NoteStatus.complete.displayName, "Complete")
        XCTAssertEqual(NoteStatus.signed.displayName, "Signed")
        XCTAssertEqual(NoteStatus.addendum.displayName, "Addendum")
    }

    func testNoteStatus_IconNames() {
        XCTAssertEqual(NoteStatus.draft.iconName, "doc.badge.ellipsis")
        XCTAssertEqual(NoteStatus.complete.iconName, "doc.badge.checkmark")
        XCTAssertEqual(NoteStatus.signed.iconName, "signature")
        XCTAssertEqual(NoteStatus.addendum.iconName, "doc.badge.plus")
    }

    func testNoteStatus_AllCases() {
        XCTAssertEqual(NoteStatus.allCases.count, 4)
    }

    func testNoteStatus_Identifiable() {
        XCTAssertEqual(NoteStatus.draft.id, "draft")
        XCTAssertEqual(NoteStatus.complete.id, "complete")
    }
}

// MARK: - Service Error Tests

final class SOAPNoteServiceErrorTests: XCTestCase {

    func testFetchFailed_Description() {
        let error = SOAPNoteServiceError.fetchFailed(NSError(domain: "test", code: -1))

        XCTAssertEqual(error.errorDescription, "Failed to fetch SOAP notes")
    }

    func testSaveFailed_Description() {
        let error = SOAPNoteServiceError.saveFailed(NSError(domain: "test", code: -1))

        XCTAssertEqual(error.errorDescription, "Failed to save SOAP note")
    }

    func testCannotEditSigned_Description() {
        let error = SOAPNoteServiceError.cannotEditSigned

        XCTAssertEqual(error.errorDescription, "Cannot edit a signed note. Create an addendum instead.")
    }

    func testCannotDeleteSigned_Description() {
        let error = SOAPNoteServiceError.cannotDeleteSigned

        XCTAssertEqual(error.errorDescription, "Cannot delete a signed note")
    }

    func testNoteNotReadyForSignature_Description() {
        let error = SOAPNoteServiceError.noteNotReadyForSignature

        XCTAssertEqual(error.errorDescription, "Note must be marked complete before signing")
    }

    func testIncompleteNote_Description() {
        let error = SOAPNoteServiceError.incompleteNote

        XCTAssertTrue(error.errorDescription?.contains("SOAP sections") ?? false)
    }

    func testMissingPatientId_Description() {
        let error = SOAPNoteServiceError.missingPatientId

        XCTAssertEqual(error.errorDescription, "Patient ID is required")
    }

    func testNoteNotFound_Description() {
        let error = SOAPNoteServiceError.noteNotFound

        XCTAssertEqual(error.errorDescription, "SOAP note not found")
    }

    func testRecoverySuggestion_CannotEditSigned() {
        let error = SOAPNoteServiceError.cannotEditSigned

        XCTAssertEqual(error.recoverySuggestion, "Create an addendum to add information to this note.")
    }

    func testRecoverySuggestion_CannotDeleteSigned() {
        let error = SOAPNoteServiceError.cannotDeleteSigned

        XCTAssertEqual(error.recoverySuggestion, "Signed notes are part of the permanent medical record.")
    }
}

// MARK: - SOAP Note Template Tests

final class SOAPNoteTemplateValidationTests: XCTestCase {

    func testSOAPNoteTemplate_Init() {
        let id = UUID()
        let template = SOAPNoteTemplate(
            id: id,
            name: "Initial Evaluation",
            description: "Template for initial evaluations",
            category: "evaluation",
            subjective: "Patient presents with...",
            objective: "ROM: ...",
            assessment: "Patient demonstrates...",
            plan: "Plan of care...",
            defaultCptCodes: ["97163"],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(template.id, id)
        XCTAssertEqual(template.name, "Initial Evaluation")
        XCTAssertEqual(template.category, "evaluation")
        XCTAssertEqual(template.defaultCptCodes, ["97163"])
        XCTAssertTrue(template.isActive)
    }

    func testSOAPNoteTemplate_OptionalFields() {
        let template = SOAPNoteTemplate(
            id: UUID(),
            name: "Minimal",
            description: nil,
            category: nil,
            subjective: nil,
            objective: nil,
            assessment: nil,
            plan: nil,
            defaultCptCodes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(template.description)
        XCTAssertNil(template.category)
        XCTAssertNil(template.defaultCptCodes)
    }
}

// MARK: - CPT Codes Tests

final class CPTCodesValidationTests: XCTestCase {

    func testEvaluationCodes_Count() {
        XCTAssertEqual(CommonCPTCodes.evaluations.count, 4)
    }

    func testEvaluationCodes_ContainsExpectedCodes() {
        let codes = CommonCPTCodes.evaluations.map { $0.code }

        XCTAssertTrue(codes.contains("97161"))
        XCTAssertTrue(codes.contains("97162"))
        XCTAssertTrue(codes.contains("97163"))
        XCTAssertTrue(codes.contains("97164"))
    }

    func testTherapeuticCodes_Count() {
        XCTAssertEqual(CommonCPTCodes.therapeuticExercise.count, 4)
    }

    func testTherapeuticCodes_ContainsExpectedCodes() {
        let codes = CommonCPTCodes.therapeuticExercise.map { $0.code }

        XCTAssertTrue(codes.contains("97110"))
        XCTAssertTrue(codes.contains("97112"))
        XCTAssertTrue(codes.contains("97530"))
        XCTAssertTrue(codes.contains("97535"))
    }

    func testManualTherapyCodes_Count() {
        XCTAssertEqual(CommonCPTCodes.manualTherapy.count, 2)
    }

    func testModalitiesCodes_Count() {
        XCTAssertEqual(CommonCPTCodes.modalities.count, 5)
    }

    func testCPTCode_HasRequiredProperties() {
        guard let code = CommonCPTCodes.evaluations.first else {
            XCTFail("No evaluation codes")
            return
        }

        XCTAssertNotNil(code.id)
        XCTAssertFalse(code.code.isEmpty)
        XCTAssertFalse(code.description.isEmpty)
    }
}

// MARK: - Edge Cases Tests

final class SOAPNoteEdgeCasesTests: XCTestCase {

    func testPainLevel_BoundaryZero() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            painLevel: 0
        )

        XCTAssertEqual(note.painLevel, 0)
    }

    func testPainLevel_BoundaryTen() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            painLevel: 10
        )

        XCTAssertEqual(note.painLevel, 10)
    }

    func testTimeSpent_LargeValue() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 480
        )

        XCTAssertEqual(note.formattedTimeSpent, "8h")
    }

    func testManyCptCodes() {
        let codes = (0..<20).map { "9710\($0)" }
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: codes
        )

        XCTAssertEqual(note.cptCodes?.count, 20)
    }

    func testLongSubjectiveText() {
        let longText = String(repeating: "Patient reports. ", count: 100)
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: longText
        )

        XCTAssertEqual(note.subjective, longText)
    }

    func testVitals_ExtremeValues() {
        let vitals = Vitals(
            bloodPressure: "200/120",
            heartRate: 200,
            temperature: 104.5,
            respiratoryRate: 40,
            oxygenSaturation: 70,
            weight: 400.0
        )

        XCTAssertTrue(vitals.hasData)
        XCTAssertFalse(vitals.summary.isEmpty)
    }
}

// MARK: - Service Tests

@MainActor
final class SOAPNoteServiceValidationTests: XCTestCase {

    var sut: SOAPNoteService!

    override func setUp() async throws {
        try await super.setUp()
        sut = SOAPNoteService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testSharedInstance_Exists() {
        XCTAssertNotNil(SOAPNoteService.shared)
    }

    func testSharedInstance_IsSingleton() {
        let instance1 = SOAPNoteService.shared
        let instance2 = SOAPNoteService.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testNotes_IsArray() {
        XCTAssertNotNil(sut.notes)
    }

    func testNotesByStatus_ReturnsArray() {
        let drafts = sut.notes(byStatus: .draft)

        XCTAssertNotNil(drafts)
    }

    func testNotesForSession_ReturnsArray() {
        let sessionNotes = sut.notes(forSession: UUID().uuidString)

        XCTAssertNotNil(sessionNotes)
    }

    func testClearError_SetsNil() {
        sut.clearError()

        XCTAssertNil(sut.error)
    }

    func testQueueForAutoSave_DraftNote() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            status: .draft
        )

        sut.queueForAutoSave(note)

        // Should not throw
        XCTAssertTrue(true)
    }

    func testSetAutoSaveInterval() {
        sut.setAutoSaveInterval(60.0)

        // Should not throw
        XCTAssertTrue(true)
    }
}
