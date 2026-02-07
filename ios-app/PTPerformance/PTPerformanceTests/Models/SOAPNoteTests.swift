//
//  SOAPNoteTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for SOAPNote model
//  Tests encoding/decoding, SOAP sections, signing workflow, and visit type validation
//

import XCTest
@testable import PTPerformance

// MARK: - SOAPNote Model Tests

final class SOAPNoteModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSOAPNote_DefaultInitialization() {
        let patientId = UUID()
        let therapistId = UUID()

        let note = SOAPNote(
            patientId: patientId,
            therapistId: therapistId
        )

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.patientId, patientId)
        XCTAssertEqual(note.therapistId, therapistId)
        XCTAssertNil(note.sessionId)
        XCTAssertNil(note.subjective)
        XCTAssertNil(note.objective)
        XCTAssertNil(note.assessment)
        XCTAssertNil(note.plan)
        XCTAssertNil(note.vitals)
        XCTAssertNil(note.painLevel)
        XCTAssertNil(note.functionalStatus)
        XCTAssertNil(note.timeSpentMinutes)
        XCTAssertNil(note.cptCodes)
        XCTAssertEqual(note.status, .draft)
        XCTAssertNil(note.signedAt)
        XCTAssertNil(note.signedBy)
        XCTAssertNil(note.parentNoteId)
    }

    func testSOAPNote_FullInitialization() {
        let id = UUID()
        let patientId = UUID()
        let therapistId = UUID()
        let sessionId = UUID()
        let noteDate = Date()
        let signedAt = Date()
        let parentNoteId = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        let vitals = Vitals(bloodPressure: "120/80", heartRate: 72)

        let note = SOAPNote(
            id: id,
            patientId: patientId,
            therapistId: therapistId,
            sessionId: sessionId,
            noteDate: noteDate,
            subjective: "Patient reports decreased pain",
            objective: "ROM improved to 160 degrees",
            assessment: "Good progress",
            plan: "Continue current program",
            vitals: vitals,
            painLevel: 4,
            functionalStatus: .improving,
            timeSpentMinutes: 45,
            cptCodes: ["97110", "97140"],
            status: .signed,
            signedAt: signedAt,
            signedBy: "Dr. Smith, PT",
            parentNoteId: parentNoteId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.patientId, patientId)
        XCTAssertEqual(note.therapistId, therapistId)
        XCTAssertEqual(note.sessionId, sessionId)
        XCTAssertEqual(note.noteDate, noteDate)
        XCTAssertEqual(note.subjective, "Patient reports decreased pain")
        XCTAssertEqual(note.objective, "ROM improved to 160 degrees")
        XCTAssertEqual(note.assessment, "Good progress")
        XCTAssertEqual(note.plan, "Continue current program")
        XCTAssertEqual(note.vitals?.bloodPressure, "120/80")
        XCTAssertEqual(note.painLevel, 4)
        XCTAssertEqual(note.functionalStatus, .improving)
        XCTAssertEqual(note.timeSpentMinutes, 45)
        XCTAssertEqual(note.cptCodes, ["97110", "97140"])
        XCTAssertEqual(note.status, .signed)
        XCTAssertEqual(note.signedAt, signedAt)
        XCTAssertEqual(note.signedBy, "Dr. Smith, PT")
        XCTAssertEqual(note.parentNoteId, parentNoteId)
    }

    // MARK: - SOAP Sections Tests

    func testSOAPNote_SubjectiveSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Patient reports pain level 5/10 at rest, increasing to 7/10 with activity. Sleep disturbed due to pain."
        )

        XCTAssertNotNil(note.subjective)
        XCTAssertTrue(note.subjective!.contains("pain level"))
    }

    func testSOAPNote_ObjectiveSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            objective: "ROM: Shoulder flexion 140 degrees. Strength 4/5. Special tests: Hawkins positive."
        )

        XCTAssertNotNil(note.objective)
        XCTAssertTrue(note.objective!.contains("ROM"))
    }

    func testSOAPNote_AssessmentSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            assessment: "Patient demonstrating improved ROM and decreased pain. On track to meet goals."
        )

        XCTAssertNotNil(note.assessment)
        XCTAssertTrue(note.assessment!.contains("improved"))
    }

    func testSOAPNote_PlanSection() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            plan: "Continue therapeutic exercise. Progress to resistance training. Reassess in 2 weeks."
        )

        XCTAssertNotNil(note.plan)
        XCTAssertTrue(note.plan!.contains("Continue"))
    }

    // MARK: - Completeness Tests

    func testSOAPNote_CompletenessPercentage_Empty() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertEqual(note.completenessPercentage, 0.0)
    }

    func testSOAPNote_CompletenessPercentage_OneSectionFilled() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Content"
        )

        XCTAssertEqual(note.completenessPercentage, 25.0)
    }

    func testSOAPNote_CompletenessPercentage_TwoSectionsFilled() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Content",
            objective: "Content"
        )

        XCTAssertEqual(note.completenessPercentage, 50.0)
    }

    func testSOAPNote_CompletenessPercentage_ThreeSectionsFilled() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Content",
            objective: "Content",
            assessment: "Content"
        )

        XCTAssertEqual(note.completenessPercentage, 75.0)
    }

    func testSOAPNote_CompletenessPercentage_AllSectionsFilled() {
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

    func testSOAPNote_CompletenessPercentage_EmptyStringsDoNotCount() {
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

    // MARK: - Signing Workflow Tests

    func testSOAPNote_IsReadyForSignature_Complete() {
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

    func testSOAPNote_IsReadyForSignature_Draft() {
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

    func testSOAPNote_IsReadyForSignature_MissingSubjective() {
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

    func testSOAPNote_IsReadyForSignature_MissingObjective() {
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

    func testSOAPNote_IsReadyForSignature_MissingAssessment() {
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

    func testSOAPNote_IsReadyForSignature_MissingPlan() {
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

    func testSOAPNote_IsReadyForSignature_AlreadySigned() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .signed
        )

        XCTAssertFalse(note.isReadyForSignature)
    }

    // MARK: - Addendum Tests

    func testSOAPNote_IsAddendum_WithParentNote() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            parentNoteId: UUID()
        )

        XCTAssertTrue(note.isAddendum)
    }

    func testSOAPNote_IsAddendum_WithAddendumStatus() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            status: .addendum
        )

        XCTAssertTrue(note.isAddendum)
    }

    func testSOAPNote_IsAddendum_RegularNote() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            status: .draft
        )

        XCTAssertFalse(note.isAddendum)
    }

    // MARK: - Formatted Properties Tests

    func testSOAPNote_FormattedDate_ReturnsNonEmpty() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertFalse(note.formattedDate.isEmpty)
    }

    func testSOAPNote_FormattedDateTime_ReturnsNonEmpty() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertFalse(note.formattedDateTime.isEmpty)
    }

    func testSOAPNote_FormattedTimeSpent_Nil() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertNil(note.formattedTimeSpent)
    }

    func testSOAPNote_FormattedTimeSpent_MinutesOnly() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 45
        )

        XCTAssertEqual(note.formattedTimeSpent, "45 min")
    }

    func testSOAPNote_FormattedTimeSpent_ExactHour() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 60
        )

        XCTAssertEqual(note.formattedTimeSpent, "1h")
    }

    func testSOAPNote_FormattedTimeSpent_HoursAndMinutes() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 90
        )

        XCTAssertEqual(note.formattedTimeSpent, "1h 30m")
    }

    func testSOAPNote_FormattedTimeSpent_MultipleHours() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 150
        )

        XCTAssertEqual(note.formattedTimeSpent, "2h 30m")
    }

    func testSOAPNote_FormattedCptCodes_Nil() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertNil(note.formattedCptCodes)
    }

    func testSOAPNote_FormattedCptCodes_Empty() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: []
        )

        XCTAssertNil(note.formattedCptCodes)
    }

    func testSOAPNote_FormattedCptCodes_SingleCode() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: ["97110"]
        )

        XCTAssertEqual(note.formattedCptCodes, "97110")
    }

    func testSOAPNote_FormattedCptCodes_MultipleCodes() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: ["97110", "97140", "97530"]
        )

        XCTAssertEqual(note.formattedCptCodes, "97110, 97140, 97530")
    }

    func testSOAPNote_PreviewText_WithContent() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "Patient reports improvement"
        )

        XCTAssertEqual(note.previewText, "Patient reports improvement")
    }

    func testSOAPNote_PreviewText_NoContent() {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID()
        )

        XCTAssertEqual(note.previewText, "No content")
    }

    func testSOAPNote_PreviewText_Truncated() {
        let longText = String(repeating: "a", count: 150)
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: longText
        )

        XCTAssertTrue(note.previewText.hasSuffix("..."))
        XCTAssertLessThanOrEqual(note.previewText.count, 103)
    }

    // MARK: - Encoding/Decoding Tests

    func testSOAPNote_EncodeDecode() throws {
        let original = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            painLevel: 5,
            functionalStatus: .improving,
            timeSpentMinutes: 45,
            cptCodes: ["97110"],
            status: .draft
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SOAPNote.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.subjective, decoded.subjective)
        XCTAssertEqual(original.objective, decoded.objective)
        XCTAssertEqual(original.assessment, decoded.assessment)
        XCTAssertEqual(original.plan, decoded.plan)
        XCTAssertEqual(original.painLevel, decoded.painLevel)
        XCTAssertEqual(original.functionalStatus, decoded.functionalStatus)
        XCTAssertEqual(original.timeSpentMinutes, decoded.timeSpentMinutes)
        XCTAssertEqual(original.cptCodes, decoded.cptCodes)
        XCTAssertEqual(original.status, decoded.status)
    }

    func testSOAPNote_CodingKeysMapping() throws {
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            painLevel: 5,
            timeSpentMinutes: 45
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(note)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["therapist_id"])
        XCTAssertNotNil(jsonObject["note_date"])
        XCTAssertNotNil(jsonObject["pain_level"])
        XCTAssertNotNil(jsonObject["time_spent_minutes"])
        XCTAssertNotNil(jsonObject["created_at"])
        XCTAssertNotNil(jsonObject["updated_at"])

        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["painLevel"])
        XCTAssertNil(jsonObject["timeSpentMinutes"])
    }

    func testSOAPNote_DecodingFromJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "session_id": "880e8400-e29b-41d4-a716-446655440003",
            "note_date": "2024-03-15T10:30:00Z",
            "subjective": "Patient reports decreased pain",
            "objective": "ROM improved",
            "assessment": "Good progress",
            "plan": "Continue exercises",
            "vitals": {
                "blood_pressure": "120/80",
                "heart_rate": 72
            },
            "pain_level": 4,
            "functional_status": "improving",
            "time_spent_minutes": 45,
            "cpt_codes": ["97110", "97140"],
            "status": "complete",
            "signed_at": null,
            "signed_by": null,
            "parent_note_id": null,
            "created_at": "2024-03-15T10:30:00Z",
            "updated_at": "2024-03-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let note = try decoder.decode(SOAPNote.self, from: json)

        XCTAssertEqual(note.subjective, "Patient reports decreased pain")
        XCTAssertEqual(note.objective, "ROM improved")
        XCTAssertEqual(note.assessment, "Good progress")
        XCTAssertEqual(note.plan, "Continue exercises")
        XCTAssertEqual(note.vitals?.bloodPressure, "120/80")
        XCTAssertEqual(note.vitals?.heartRate, 72)
        XCTAssertEqual(note.painLevel, 4)
        XCTAssertEqual(note.functionalStatus, .improving)
        XCTAssertEqual(note.timeSpentMinutes, 45)
        XCTAssertEqual(note.cptCodes, ["97110", "97140"])
        XCTAssertEqual(note.status, .complete)
    }

    func testSOAPNote_DecodingWithNulls() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "therapist_id": "770e8400-e29b-41d4-a716-446655440002",
            "session_id": null,
            "note_date": "2024-03-15T10:30:00Z",
            "subjective": null,
            "objective": null,
            "assessment": null,
            "plan": null,
            "vitals": null,
            "pain_level": null,
            "functional_status": null,
            "time_spent_minutes": null,
            "cpt_codes": null,
            "status": "draft",
            "signed_at": null,
            "signed_by": null,
            "parent_note_id": null,
            "created_at": "2024-03-15T10:30:00Z",
            "updated_at": "2024-03-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let note = try decoder.decode(SOAPNote.self, from: json)

        XCTAssertNil(note.sessionId)
        XCTAssertNil(note.subjective)
        XCTAssertNil(note.objective)
        XCTAssertNil(note.assessment)
        XCTAssertNil(note.plan)
        XCTAssertNil(note.vitals)
        XCTAssertNil(note.painLevel)
        XCTAssertNil(note.functionalStatus)
        XCTAssertNil(note.timeSpentMinutes)
        XCTAssertNil(note.cptCodes)
        XCTAssertEqual(note.status, .draft)
    }

    // MARK: - Edge Cases

    func testSOAPNote_PainLevel_BoundaryValues() {
        let noteZero = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            painLevel: 0
        )
        XCTAssertEqual(noteZero.painLevel, 0)

        let noteTen = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            painLevel: 10
        )
        XCTAssertEqual(noteTen.painLevel, 10)
    }

    func testSOAPNote_TimeSpent_EdgeCases() {
        let noteZeroTime = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 0
        )
        XCTAssertNotNil(noteZeroTime.formattedTimeSpent)

        let noteLargeTime = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            timeSpentMinutes: 480 // 8 hours
        )
        XCTAssertEqual(noteLargeTime.formattedTimeSpent, "8h")
    }

    func testSOAPNote_ManyCptCodes() {
        let codes = (0..<20).map { "9710\($0)" }
        let note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            cptCodes: codes
        )

        XCTAssertEqual(note.cptCodes?.count, 20)
        XCTAssertNotNil(note.formattedCptCodes)
    }
}

// MARK: - NoteStatus Comprehensive Tests

final class NoteStatusComprehensiveTests: XCTestCase {

    func testNoteStatus_AllRawValues() {
        XCTAssertEqual(NoteStatus.draft.rawValue, "draft")
        XCTAssertEqual(NoteStatus.complete.rawValue, "complete")
        XCTAssertEqual(NoteStatus.signed.rawValue, "signed")
        XCTAssertEqual(NoteStatus.addendum.rawValue, "addendum")
    }

    func testNoteStatus_InitFromRawValue() {
        XCTAssertEqual(NoteStatus(rawValue: "draft"), .draft)
        XCTAssertEqual(NoteStatus(rawValue: "complete"), .complete)
        XCTAssertEqual(NoteStatus(rawValue: "signed"), .signed)
        XCTAssertEqual(NoteStatus(rawValue: "addendum"), .addendum)
        XCTAssertNil(NoteStatus(rawValue: "invalid"))
        XCTAssertNil(NoteStatus(rawValue: "DRAFT"))
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

    func testNoteStatus_IsEditable() {
        XCTAssertTrue(NoteStatus.draft.isEditable)
        XCTAssertFalse(NoteStatus.complete.isEditable)
        XCTAssertFalse(NoteStatus.signed.isEditable)
        XCTAssertTrue(NoteStatus.addendum.isEditable)
    }

    func testNoteStatus_CaseIterable() {
        let allCases = NoteStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.draft))
        XCTAssertTrue(allCases.contains(.complete))
        XCTAssertTrue(allCases.contains(.signed))
        XCTAssertTrue(allCases.contains(.addendum))
    }

    func testNoteStatus_Identifiable() {
        XCTAssertEqual(NoteStatus.draft.id, "draft")
        XCTAssertEqual(NoteStatus.complete.id, "complete")
        XCTAssertEqual(NoteStatus.signed.id, "signed")
        XCTAssertEqual(NoteStatus.addendum.id, "addendum")
    }

    func testNoteStatus_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in NoteStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(NoteStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testNoteStatus_ColorsAssigned() {
        for status in NoteStatus.allCases {
            XCTAssertNotNil(status.color)
        }
    }
}

// MARK: - FunctionalStatus Comprehensive Tests

final class FunctionalStatusComprehensiveTests: XCTestCase {

    func testFunctionalStatus_AllRawValues() {
        XCTAssertEqual(FunctionalStatus.improving.rawValue, "improving")
        XCTAssertEqual(FunctionalStatus.stable.rawValue, "stable")
        XCTAssertEqual(FunctionalStatus.declining.rawValue, "declining")
    }

    func testFunctionalStatus_InitFromRawValue() {
        XCTAssertEqual(FunctionalStatus(rawValue: "improving"), .improving)
        XCTAssertEqual(FunctionalStatus(rawValue: "stable"), .stable)
        XCTAssertEqual(FunctionalStatus(rawValue: "declining"), .declining)
        XCTAssertNil(FunctionalStatus(rawValue: "invalid"))
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

    func testFunctionalStatus_CaseIterable() {
        let allCases = FunctionalStatus.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.improving))
        XCTAssertTrue(allCases.contains(.stable))
        XCTAssertTrue(allCases.contains(.declining))
    }

    func testFunctionalStatus_Codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in FunctionalStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(FunctionalStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testFunctionalStatus_ColorsAssigned() {
        for status in FunctionalStatus.allCases {
            XCTAssertNotNil(status.color)
        }
    }
}

// MARK: - Vitals Comprehensive Tests

final class VitalsComprehensiveTests: XCTestCase {

    func testVitals_FullInitialization() {
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

    func testVitals_EmptyInitialization() {
        let vitals = Vitals()

        XCTAssertNil(vitals.bloodPressure)
        XCTAssertNil(vitals.heartRate)
        XCTAssertNil(vitals.temperature)
        XCTAssertNil(vitals.respiratoryRate)
        XCTAssertNil(vitals.oxygenSaturation)
        XCTAssertNil(vitals.weight)
    }

    func testVitals_HasData_WithAnyValue() {
        XCTAssertTrue(Vitals(bloodPressure: "120/80").hasData)
        XCTAssertTrue(Vitals(heartRate: 72).hasData)
        XCTAssertTrue(Vitals(temperature: 98.6).hasData)
        XCTAssertTrue(Vitals(respiratoryRate: 16).hasData)
        XCTAssertTrue(Vitals(oxygenSaturation: 98).hasData)
        XCTAssertTrue(Vitals(weight: 175.5).hasData)
    }

    func testVitals_HasData_Empty() {
        XCTAssertFalse(Vitals().hasData)
    }

    func testVitals_Summary_Full() {
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
        XCTAssertFalse(summary.contains("RR"))
        XCTAssertFalse(summary.contains("O2"))
    }

    func testVitals_Summary_Empty() {
        let vitals = Vitals()
        XCTAssertEqual(vitals.summary, "")
    }

    func testVitals_Equatable() {
        let vitals1 = Vitals(bloodPressure: "120/80", heartRate: 72)
        let vitals2 = Vitals(bloodPressure: "120/80", heartRate: 72)
        let vitals3 = Vitals(bloodPressure: "130/85", heartRate: 72)

        XCTAssertEqual(vitals1, vitals2)
        XCTAssertNotEqual(vitals1, vitals3)
    }

    func testVitals_Codable() throws {
        let original = Vitals(
            bloodPressure: "120/80",
            heartRate: 72,
            temperature: 98.6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Vitals.self, from: data)

        XCTAssertEqual(original, decoded)
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

// MARK: - SOAPNoteInput Validation Tests (Model)

final class SOAPNoteModelInputValidationTests: XCTestCase {

    func testValidate_ValidInput() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 5,
            timeSpentMinutes: 45
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_PainLevel_Zero() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 0
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_PainLevel_Ten() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 10
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_PainLevel_Negative() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: -1
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case SOAPNoteError.invalidPainLevel(let message) = error else {
                XCTFail("Expected invalidPainLevel error")
                return
            }
            XCTAssertEqual(message, "Pain level must be 0-10")
        }
    }

    func testValidate_PainLevel_TooHigh() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            painLevel: 11
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case SOAPNoteError.invalidPainLevel = error else {
                XCTFail("Expected invalidPainLevel error")
                return
            }
        }
    }

    func testValidate_TimeSpent_Zero() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            timeSpentMinutes: 0
        )

        XCTAssertNoThrow(try input.validate())
    }

    func testValidate_TimeSpent_Negative() {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString,
            timeSpentMinutes: -1
        )

        XCTAssertThrowsError(try input.validate()) { error in
            guard case SOAPNoteError.invalidTimeSpent(let message) = error else {
                XCTFail("Expected invalidTimeSpent error")
                return
            }
            XCTAssertEqual(message, "Time spent cannot be negative")
        }
    }

    func testValidate_NilValues() throws {
        let input = SOAPNoteInput(
            patientId: UUID().uuidString,
            therapistId: UUID().uuidString
        )

        XCTAssertNoThrow(try input.validate())
    }
}

// MARK: - SOAPNoteError Tests

final class SOAPNoteErrorComprehensiveTests: XCTestCase {

    func testError_InvalidPainLevel() {
        let error = SOAPNoteError.invalidPainLevel("Custom message")
        XCTAssertEqual(error.errorDescription, "Custom message")
    }

    func testError_InvalidTimeSpent() {
        let error = SOAPNoteError.invalidTimeSpent("Time cannot be negative")
        XCTAssertEqual(error.errorDescription, "Time cannot be negative")
    }

    func testError_NoteNotFound() {
        let error = SOAPNoteError.noteNotFound
        XCTAssertEqual(error.errorDescription, "SOAP note not found")
    }

    func testError_SaveFailed() {
        let error = SOAPNoteError.saveFailed
        XCTAssertEqual(error.errorDescription, "Failed to save SOAP note")
    }

    func testError_FetchFailed() {
        let error = SOAPNoteError.fetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch SOAP note")
    }

    func testError_CannotEditSigned() {
        let error = SOAPNoteError.cannotEditSigned
        XCTAssertEqual(error.errorDescription, "Cannot edit a signed note")
    }

    func testError_IncompleteNote() {
        let error = SOAPNoteError.incompleteNote
        XCTAssertEqual(error.errorDescription, "Please complete all SOAP sections before signing")
    }
}

// MARK: - Status Workflow Tests

final class SOAPNoteStatusWorkflowTests: XCTestCase {

    func testStatusTransition_DraftToComplete() {
        var note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .draft
        )

        XCTAssertEqual(note.status, .draft)
        XCTAssertTrue(note.status.isEditable)

        note = SOAPNote(
            id: note.id,
            patientId: note.patientId,
            therapistId: note.therapistId,
            subjective: note.subjective,
            objective: note.objective,
            assessment: note.assessment,
            plan: note.plan,
            status: .complete
        )

        XCTAssertEqual(note.status, .complete)
        XCTAssertFalse(note.status.isEditable)
        XCTAssertTrue(note.isReadyForSignature)
    }

    func testStatusTransition_CompleteToSigned() {
        var note = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .complete
        )

        XCTAssertTrue(note.isReadyForSignature)

        note = SOAPNote(
            id: note.id,
            patientId: note.patientId,
            therapistId: note.therapistId,
            subjective: note.subjective,
            objective: note.objective,
            assessment: note.assessment,
            plan: note.plan,
            status: .signed,
            signedAt: Date(),
            signedBy: "Dr. Smith, PT"
        )

        XCTAssertEqual(note.status, .signed)
        XCTAssertFalse(note.status.isEditable)
        XCTAssertNotNil(note.signedAt)
        XCTAssertNotNil(note.signedBy)
    }

    func testStatusTransition_SignedToAddendum() {
        let originalNote = SOAPNote(
            patientId: UUID(),
            therapistId: UUID(),
            subjective: "S",
            objective: "O",
            assessment: "A",
            plan: "P",
            status: .signed,
            signedAt: Date(),
            signedBy: "Dr. Smith, PT"
        )

        XCTAssertFalse(originalNote.status.isEditable)

        let addendum = SOAPNote(
            patientId: originalNote.patientId,
            therapistId: originalNote.therapistId,
            subjective: "Addendum: Patient reported new symptoms",
            status: .addendum,
            parentNoteId: originalNote.id
        )

        XCTAssertTrue(addendum.isAddendum)
        XCTAssertTrue(addendum.status.isEditable)
        XCTAssertEqual(addendum.parentNoteId, originalNote.id)
    }
}

// MARK: - Sample Data Tests (Model)

#if DEBUG
final class SOAPNoteModelSampleDataTests: XCTestCase {

    func testSOAPNote_SampleExists() {
        let sample = SOAPNote.sample

        XCTAssertNotNil(sample.subjective)
        XCTAssertNotNil(sample.objective)
        XCTAssertNotNil(sample.assessment)
        XCTAssertNotNil(sample.plan)
        XCTAssertEqual(sample.status, .complete)
        XCTAssertEqual(sample.completenessPercentage, 100.0)
    }

    func testSOAPNote_DraftSampleExists() {
        let draft = SOAPNote.draftSample

        XCTAssertNotNil(draft.subjective)
        XCTAssertNil(draft.objective)
        XCTAssertEqual(draft.status, .draft)
    }

    func testVitals_SampleExists() {
        let sample = Vitals.sample

        XCTAssertNotNil(sample.bloodPressure)
        XCTAssertNotNil(sample.heartRate)
        XCTAssertNotNil(sample.temperature)
        XCTAssertNotNil(sample.respiratoryRate)
        XCTAssertNotNil(sample.oxygenSaturation)
        XCTAssertTrue(sample.hasData)
    }
}
#endif
