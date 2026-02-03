//
//  ParsedLabResultTests.swift
//  PTPerformanceTests
//
//  Unit tests for ParsedLabResult, ParsedBiomarker, and related parsing models
//

import XCTest
@testable import PTPerformance

// MARK: - ParsedLabResult Tests

final class ParsedLabResultTests: XCTestCase {

    // MARK: - Initialization Tests

    func testParsedLabResult_Initialization() {
        let testDate = Date()
        let biomarker = createMockParsedBiomarker()

        let result = ParsedLabResult(
            provider: .quest,
            testDate: testDate,
            patientName: "John Doe",
            orderingPhysician: "Dr. Smith",
            biomarkers: [biomarker],
            confidence: .high,
            parsingNotes: ["Successfully parsed"]
        )

        XCTAssertEqual(result.provider, .quest)
        XCTAssertEqual(result.testDate, testDate)
        XCTAssertEqual(result.patientName, "John Doe")
        XCTAssertEqual(result.orderingPhysician, "Dr. Smith")
        XCTAssertEqual(result.biomarkers.count, 1)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.parsingNotes?.count, 1)
    }

    func testParsedLabResult_OptionalFields() {
        let result = ParsedLabResult(
            provider: .unknown,
            testDate: nil,
            patientName: nil,
            orderingPhysician: nil,
            biomarkers: [],
            confidence: .low,
            parsingNotes: nil
        )

        XCTAssertEqual(result.provider, .unknown)
        XCTAssertNil(result.testDate)
        XCTAssertNil(result.patientName)
        XCTAssertNil(result.orderingPhysician)
        XCTAssertTrue(result.biomarkers.isEmpty)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertNil(result.parsingNotes)
    }

    // MARK: - Codable Tests

    func testParsedLabResult_Decoding() throws {
        let json = """
        {
            "provider": "quest",
            "test_date": "2024-01-15",
            "patient_name": "Jane Doe",
            "ordering_physician": "Dr. Johnson",
            "biomarkers": [],
            "confidence": "high",
            "parsing_notes": ["Parsed successfully", "All markers found"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let result = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(result.provider, .quest)
        XCTAssertNotNil(result.testDate)
        XCTAssertEqual(result.patientName, "Jane Doe")
        XCTAssertEqual(result.orderingPhysician, "Dr. Johnson")
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.parsingNotes?.count, 2)
    }

    func testParsedLabResult_DecodingWithStringEnums() throws {
        let json = """
        {
            "provider": "labcorp",
            "test_date": "2024-02-20",
            "biomarkers": [],
            "confidence": "medium"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let result = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(result.provider, .labcorp)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testParsedLabResult_DecodingUnknownProvider() throws {
        let json = """
        {
            "provider": "some_unknown_lab",
            "biomarkers": [],
            "confidence": "low"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let result = try decoder.decode(ParsedLabResult.self, from: json)

        XCTAssertEqual(result.provider, .unknown)
    }

    func testParsedLabResult_Encoding() throws {
        let result = ParsedLabResult(
            provider: .quest,
            testDate: Date(),
            biomarkers: [],
            confidence: .high
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(jsonObject["provider"])
        XCTAssertNotNil(jsonObject["test_date"])
        XCTAssertNotNil(jsonObject["biomarkers"])
        XCTAssertNotNil(jsonObject["confidence"])
    }

    // MARK: - Equatable Tests

    func testParsedLabResult_Equatable() {
        let date = Date()
        let biomarker = createMockParsedBiomarker()

        let result1 = ParsedLabResult(
            provider: .quest,
            testDate: date,
            biomarkers: [biomarker],
            confidence: .high
        )

        let result2 = ParsedLabResult(
            provider: .quest,
            testDate: date,
            biomarkers: [biomarker],
            confidence: .high
        )

        XCTAssertEqual(result1, result2)
    }

    // MARK: - Helper Methods

    private func createMockParsedBiomarker() -> ParsedBiomarker {
        ParsedBiomarker(
            id: UUID(),
            name: "Hemoglobin",
            value: 14.5,
            unit: "g/dL",
            referenceRange: "12.0-17.0",
            referenceLow: 12.0,
            referenceHigh: 17.0,
            flag: .normal,
            category: "Hematology",
            isSelected: true
        )
    }
}

// MARK: - LabProvider Tests

final class LabProviderTests: XCTestCase {

    func testLabProvider_RawValues() {
        XCTAssertEqual(LabProvider.quest.rawValue, "quest")
        XCTAssertEqual(LabProvider.labcorp.rawValue, "labcorp")
        XCTAssertEqual(LabProvider.unknown.rawValue, "unknown")
    }

    func testLabProvider_DisplayNames() {
        XCTAssertEqual(LabProvider.quest.displayName, "Quest Diagnostics")
        XCTAssertEqual(LabProvider.labcorp.displayName, "LabCorp")
        XCTAssertEqual(LabProvider.unknown.displayName, "Unknown Provider")
    }

    func testLabProvider_InitFromRawValue() {
        XCTAssertEqual(LabProvider(rawValue: "quest"), .quest)
        XCTAssertEqual(LabProvider(rawValue: "Quest"), .quest)
        XCTAssertEqual(LabProvider(rawValue: "Quest Diagnostics"), .quest)
        XCTAssertEqual(LabProvider(rawValue: "labcorp"), .labcorp)
        XCTAssertEqual(LabProvider(rawValue: "LabCorp"), .labcorp)
        XCTAssertEqual(LabProvider(rawValue: "Laboratory Corporation of America"), .labcorp)
        XCTAssertEqual(LabProvider(rawValue: "random_lab"), .unknown)
        XCTAssertEqual(LabProvider(rawValue: ""), .unknown)
    }

    func testLabProvider_AllCases() {
        let allCases = LabProvider.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.quest))
        XCTAssertTrue(allCases.contains(.labcorp))
        XCTAssertTrue(allCases.contains(.unknown))
    }
}

// MARK: - ParsingConfidence Tests

final class ParsingConfidenceTests: XCTestCase {

    func testParsingConfidence_RawValues() {
        XCTAssertEqual(ParsingConfidence.high.rawValue, "high")
        XCTAssertEqual(ParsingConfidence.medium.rawValue, "medium")
        XCTAssertEqual(ParsingConfidence.low.rawValue, "low")
    }

    func testParsingConfidence_DisplayNames() {
        XCTAssertEqual(ParsingConfidence.high.displayName, "High Confidence")
        XCTAssertEqual(ParsingConfidence.medium.displayName, "Medium Confidence")
        XCTAssertEqual(ParsingConfidence.low.displayName, "Low Confidence")
    }

    func testParsingConfidence_IconNames() {
        XCTAssertEqual(ParsingConfidence.high.iconName, "checkmark.circle.fill")
        XCTAssertEqual(ParsingConfidence.medium.iconName, "exclamationmark.circle.fill")
        XCTAssertEqual(ParsingConfidence.low.iconName, "questionmark.circle.fill")
    }
}

// MARK: - ParsedBiomarker Tests

final class ParsedBiomarkerTests: XCTestCase {

    func testParsedBiomarker_Initialization() {
        let id = UUID()
        let biomarker = ParsedBiomarker(
            id: id,
            name: "Glucose",
            value: 95.0,
            unit: "mg/dL",
            referenceRange: "70-100",
            referenceLow: 70.0,
            referenceHigh: 100.0,
            flag: .normal,
            category: "Metabolic",
            isSelected: true
        )

        XCTAssertEqual(biomarker.id, id)
        XCTAssertEqual(biomarker.name, "Glucose")
        XCTAssertEqual(biomarker.value, 95.0)
        XCTAssertEqual(biomarker.unit, "mg/dL")
        XCTAssertEqual(biomarker.referenceRange, "70-100")
        XCTAssertEqual(biomarker.referenceLow, 70.0)
        XCTAssertEqual(biomarker.referenceHigh, 100.0)
        XCTAssertEqual(biomarker.flag, .normal)
        XCTAssertEqual(biomarker.category, "Metabolic")
        XCTAssertTrue(biomarker.isSelected)
    }

    func testParsedBiomarker_OptionalFields() {
        let biomarker = ParsedBiomarker(
            name: "Custom Marker",
            value: 50.0,
            unit: "units"
        )

        XCTAssertNotNil(biomarker.id)
        XCTAssertNil(biomarker.referenceRange)
        XCTAssertNil(biomarker.referenceLow)
        XCTAssertNil(biomarker.referenceHigh)
        XCTAssertNil(biomarker.flag)
        XCTAssertNil(biomarker.category)
        XCTAssertTrue(biomarker.isSelected) // Default value
    }

    func testParsedBiomarker_Decoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "TSH",
            "value": 2.5,
            "unit": "mIU/L",
            "reference_range": "0.4-4.0",
            "reference_low": 0.4,
            "reference_high": 4.0,
            "flag": "normal",
            "category": "Thyroid",
            "is_selected": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let biomarker = try decoder.decode(ParsedBiomarker.self, from: json)

        XCTAssertEqual(biomarker.name, "TSH")
        XCTAssertEqual(biomarker.value, 2.5)
        XCTAssertEqual(biomarker.unit, "mIU/L")
        XCTAssertEqual(biomarker.flag, .normal)
    }

    func testParsedBiomarker_DecodingWithNullOptionals() throws {
        let json = """
        {
            "name": "Custom",
            "value": 100.0,
            "unit": "units",
            "reference_range": null,
            "reference_low": null,
            "reference_high": null,
            "flag": null,
            "category": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let biomarker = try decoder.decode(ParsedBiomarker.self, from: json)

        XCTAssertNil(biomarker.referenceRange)
        XCTAssertNil(biomarker.referenceLow)
        XCTAssertNil(biomarker.referenceHigh)
        XCTAssertNil(biomarker.flag)
        XCTAssertNil(biomarker.category)
    }

    func testParsedBiomarker_ToLabMarker() {
        let biomarker = ParsedBiomarker(
            id: UUID(),
            name: "Hemoglobin",
            value: 14.5,
            unit: "g/dL",
            referenceRange: "12.0-17.0",
            referenceLow: 12.0,
            referenceHigh: 17.0,
            flag: .high,
            category: "Hematology",
            isSelected: true
        )

        let labMarker = biomarker.toLabMarker()

        XCTAssertEqual(labMarker.id, biomarker.id)
        XCTAssertEqual(labMarker.name, biomarker.name)
        XCTAssertEqual(labMarker.value, biomarker.value)
        XCTAssertEqual(labMarker.unit, biomarker.unit)
        XCTAssertEqual(labMarker.referenceMin, biomarker.referenceLow)
        XCTAssertEqual(labMarker.referenceMax, biomarker.referenceHigh)
        XCTAssertEqual(labMarker.status, .high)
    }

    func testParsedBiomarker_ToLabMarker_AllFlags() {
        let flags: [BiomarkerFlag: MarkerStatus] = [
            .normal: .normal,
            .low: .low,
            .high: .high,
            .critical: .critical
        ]

        for (flag, expectedStatus) in flags {
            let biomarker = ParsedBiomarker(
                name: "Test",
                value: 50.0,
                unit: "units",
                flag: flag
            )

            let labMarker = biomarker.toLabMarker()
            XCTAssertEqual(labMarker.status, expectedStatus, "Flag \(flag) should convert to status \(expectedStatus)")
        }
    }

    func testParsedBiomarker_ToLabMarker_NilFlag() {
        let biomarker = ParsedBiomarker(
            name: "Test",
            value: 50.0,
            unit: "units",
            flag: nil
        )

        let labMarker = biomarker.toLabMarker()
        XCTAssertEqual(labMarker.status, .normal) // Default when no flag
    }

    func testParsedBiomarker_Identifiable() {
        let id = UUID()
        let biomarker = ParsedBiomarker(
            id: id,
            name: "Test",
            value: 50.0,
            unit: "units"
        )

        XCTAssertEqual(biomarker.id, id)
    }

    func testParsedBiomarker_Equatable() {
        let id = UUID()

        let biomarker1 = ParsedBiomarker(
            id: id,
            name: "Test",
            value: 50.0,
            unit: "units"
        )

        let biomarker2 = ParsedBiomarker(
            id: id,
            name: "Test",
            value: 50.0,
            unit: "units"
        )

        XCTAssertEqual(biomarker1, biomarker2)
    }
}

// MARK: - BiomarkerFlag Tests

final class BiomarkerFlagTests: XCTestCase {

    func testBiomarkerFlag_RawValues() {
        XCTAssertEqual(BiomarkerFlag.normal.rawValue, "normal")
        XCTAssertEqual(BiomarkerFlag.low.rawValue, "low")
        XCTAssertEqual(BiomarkerFlag.high.rawValue, "high")
        XCTAssertEqual(BiomarkerFlag.critical.rawValue, "critical")
    }

    func testBiomarkerFlag_DisplayNames() {
        XCTAssertEqual(BiomarkerFlag.normal.displayName, "Normal")
        XCTAssertEqual(BiomarkerFlag.low.displayName, "Low")
        XCTAssertEqual(BiomarkerFlag.high.displayName, "High")
        XCTAssertEqual(BiomarkerFlag.critical.displayName, "Critical")
    }

    func testBiomarkerFlag_IconNames() {
        XCTAssertEqual(BiomarkerFlag.normal.iconName, "checkmark.circle.fill")
        XCTAssertEqual(BiomarkerFlag.low.iconName, "arrow.down.circle.fill")
        XCTAssertEqual(BiomarkerFlag.high.iconName, "arrow.up.circle.fill")
        XCTAssertEqual(BiomarkerFlag.critical.iconName, "exclamationmark.triangle.fill")
    }

    func testBiomarkerFlag_AllCases() {
        let allCases = BiomarkerFlag.allCases
        XCTAssertEqual(allCases.count, 4)
    }
}

// MARK: - ParseLabPDFResponse Tests

final class ParseLabPDFResponseTests: XCTestCase {

    func testParseLabPDFResponse_SuccessDecoding() throws {
        let json = """
        {
            "success": true,
            "provider": "quest",
            "test_date": "2024-01-15",
            "patient_name": "John Doe",
            "ordering_physician": "Dr. Smith",
            "biomarkers": [],
            "confidence": "high",
            "parsing_notes": ["Success"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.provider, "quest")
        XCTAssertEqual(response.testDate, "2024-01-15")
        XCTAssertEqual(response.patientName, "John Doe")
        XCTAssertEqual(response.orderingPhysician, "Dr. Smith")
        XCTAssertEqual(response.confidence, "high")
        XCTAssertNil(response.error)
    }

    func testParseLabPDFResponse_ErrorDecoding() throws {
        let json = """
        {
            "success": false,
            "biomarkers": [],
            "confidence": "low",
            "error": "Failed to parse PDF"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error, "Failed to parse PDF")
    }

    func testParseLabPDFResponse_ToParsedLabResult_Success() throws {
        let json = """
        {
            "success": true,
            "provider": "labcorp",
            "test_date": "2024-03-10",
            "patient_name": "Jane Doe",
            "biomarkers": [
                {
                    "name": "Glucose",
                    "value": 95.0,
                    "unit": "mg/dL"
                }
            ],
            "confidence": "medium"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)
        let parsedResult = response.toParsedLabResult()

        XCTAssertNotNil(parsedResult)
        XCTAssertEqual(parsedResult?.provider, .labcorp)
        XCTAssertEqual(parsedResult?.patientName, "Jane Doe")
        XCTAssertEqual(parsedResult?.confidence, .medium)
        XCTAssertEqual(parsedResult?.biomarkers.count, 1)
    }

    func testParseLabPDFResponse_ToParsedLabResult_Failure() throws {
        let json = """
        {
            "success": false,
            "biomarkers": [],
            "confidence": "low",
            "error": "Parse error"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)
        let parsedResult = response.toParsedLabResult()

        XCTAssertNil(parsedResult) // Should return nil on failure
    }

    func testParseLabPDFResponse_ToParsedLabResult_InvalidDate() throws {
        let json = """
        {
            "success": true,
            "test_date": "invalid-date-format",
            "biomarkers": [],
            "confidence": "low"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ParseLabPDFResponse.self, from: json)
        let parsedResult = response.toParsedLabResult()

        XCTAssertNotNil(parsedResult)
        XCTAssertNil(parsedResult?.testDate) // Date should be nil for invalid format
    }
}
