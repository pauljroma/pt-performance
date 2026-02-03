//
//  LabResultTests.swift
//  PTPerformanceTests
//
//  Unit tests for LabResult, LabTestType, LabMarker, and MarkerStatus models
//

import XCTest
@testable import PTPerformance

final class LabResultTests: XCTestCase {

    // MARK: - LabResult Initialization Tests

    func testLabResultInitialization() {
        let id = UUID()
        let patientId = UUID()
        let testDate = Date()
        let createdAt = Date()
        let updatedAt = Date()
        let marker = createLabMarker()

        let labResult = LabResult(
            id: id,
            patientId: patientId,
            testDate: testDate,
            testType: .bloodPanel,
            results: [marker],
            pdfUrl: "https://example.com/results.pdf",
            aiAnalysis: "All markers within normal range",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(labResult.id, id)
        XCTAssertEqual(labResult.patientId, patientId)
        XCTAssertEqual(labResult.testDate, testDate)
        XCTAssertEqual(labResult.testType, .bloodPanel)
        XCTAssertEqual(labResult.results.count, 1)
        XCTAssertEqual(labResult.pdfUrl, "https://example.com/results.pdf")
        XCTAssertEqual(labResult.aiAnalysis, "All markers within normal range")
        XCTAssertEqual(labResult.createdAt, createdAt)
        XCTAssertEqual(labResult.updatedAt, updatedAt)
    }

    func testLabResultWithNilOptionals() {
        let labResult = LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .other,
            results: [],
            pdfUrl: nil,
            aiAnalysis: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertNil(labResult.pdfUrl)
        XCTAssertNil(labResult.aiAnalysis)
        XCTAssertTrue(labResult.results.isEmpty)
    }

    // MARK: - LabResult Codable Tests

    func testLabResultEncodeDecode() throws {
        let original = createLabResult()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LabResult.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.patientId, decoded.patientId)
        XCTAssertEqual(original.testType, decoded.testType)
        XCTAssertEqual(original.results.count, decoded.results.count)
        XCTAssertEqual(original.pdfUrl, decoded.pdfUrl)
        XCTAssertEqual(original.aiAnalysis, decoded.aiAnalysis)
    }

    func testLabResultCodingKeysMapping() throws {
        let labResult = createLabResult()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(labResult)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["patient_id"])
        XCTAssertNotNil(jsonObject["test_date"])
        XCTAssertNotNil(jsonObject["test_type"])
        XCTAssertNotNil(jsonObject["pdf_url"])
        XCTAssertNotNil(jsonObject["ai_analysis"])
        XCTAssertNotNil(jsonObject["created_at"])
        XCTAssertNotNil(jsonObject["updated_at"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["patientId"])
        XCTAssertNil(jsonObject["testDate"])
        XCTAssertNil(jsonObject["testType"])
    }

    // MARK: - LabResult Hashable Tests

    func testLabResultHashable() {
        let labResult1 = createLabResult()
        let labResult2 = createLabResult()

        var set = Set<LabResult>()
        set.insert(labResult1)
        set.insert(labResult2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - LabTestType Tests

    func testLabTestTypeAllCases() {
        let allCases = LabTestType.allCases
        XCTAssertEqual(allCases.count, 9)
        XCTAssertTrue(allCases.contains(.bloodPanel))
        XCTAssertTrue(allCases.contains(.metabolicPanel))
        XCTAssertTrue(allCases.contains(.hormonePanel))
        XCTAssertTrue(allCases.contains(.lipidPanel))
        XCTAssertTrue(allCases.contains(.thyroid))
        XCTAssertTrue(allCases.contains(.vitaminD))
        XCTAssertTrue(allCases.contains(.iron))
        XCTAssertTrue(allCases.contains(.cbc))
        XCTAssertTrue(allCases.contains(.other))
    }

    func testLabTestTypeRawValues() {
        XCTAssertEqual(LabTestType.bloodPanel.rawValue, "blood_panel")
        XCTAssertEqual(LabTestType.metabolicPanel.rawValue, "metabolic_panel")
        XCTAssertEqual(LabTestType.hormonePanel.rawValue, "hormone_panel")
        XCTAssertEqual(LabTestType.lipidPanel.rawValue, "lipid_panel")
        XCTAssertEqual(LabTestType.thyroid.rawValue, "thyroid")
        XCTAssertEqual(LabTestType.vitaminD.rawValue, "vitamin_d")
        XCTAssertEqual(LabTestType.iron.rawValue, "iron")
        XCTAssertEqual(LabTestType.cbc.rawValue, "cbc")
        XCTAssertEqual(LabTestType.other.rawValue, "other")
    }

    func testLabTestTypeDisplayNames() {
        XCTAssertEqual(LabTestType.bloodPanel.displayName, "Blood Panel")
        XCTAssertEqual(LabTestType.metabolicPanel.displayName, "Metabolic Panel")
        XCTAssertEqual(LabTestType.hormonePanel.displayName, "Hormone Panel")
        XCTAssertEqual(LabTestType.lipidPanel.displayName, "Lipid Panel")
        XCTAssertEqual(LabTestType.thyroid.displayName, "Thyroid")
        XCTAssertEqual(LabTestType.vitaminD.displayName, "Vitamin D")
        XCTAssertEqual(LabTestType.iron.displayName, "Iron Studies")
        XCTAssertEqual(LabTestType.cbc.displayName, "Complete Blood Count")
        XCTAssertEqual(LabTestType.other.displayName, "Other")
    }

    func testLabTestTypeDisplayNamesNotEmpty() {
        for testType in LabTestType.allCases {
            XCTAssertFalse(testType.displayName.isEmpty)
            XCTAssertTrue(testType.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(testType.displayName)")
        }
    }

    func testLabTestTypeInitFromRawValue() {
        XCTAssertEqual(LabTestType(rawValue: "blood_panel"), .bloodPanel)
        XCTAssertEqual(LabTestType(rawValue: "metabolic_panel"), .metabolicPanel)
        XCTAssertNil(LabTestType(rawValue: "invalid"))
        XCTAssertNil(LabTestType(rawValue: ""))
    }

    func testLabTestTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for testType in LabTestType.allCases {
            let data = try encoder.encode(testType)
            let decoded = try decoder.decode(LabTestType.self, from: data)
            XCTAssertEqual(decoded, testType)
        }
    }

    // MARK: - LabMarker Tests

    func testLabMarkerInitialization() {
        let id = UUID()
        let marker = LabMarker(
            id: id,
            name: "Hemoglobin",
            value: 14.5,
            unit: "g/dL",
            referenceMin: 12.0,
            referenceMax: 17.0,
            status: .normal
        )

        XCTAssertEqual(marker.id, id)
        XCTAssertEqual(marker.name, "Hemoglobin")
        XCTAssertEqual(marker.value, 14.5)
        XCTAssertEqual(marker.unit, "g/dL")
        XCTAssertEqual(marker.referenceMin, 12.0)
        XCTAssertEqual(marker.referenceMax, 17.0)
        XCTAssertEqual(marker.status, .normal)
    }

    func testLabMarkerWithNilReferences() {
        let marker = LabMarker(
            id: UUID(),
            name: "Custom Marker",
            value: 100.0,
            unit: "units",
            referenceMin: nil,
            referenceMax: nil,
            status: .normal
        )

        XCTAssertNil(marker.referenceMin)
        XCTAssertNil(marker.referenceMax)
    }

    func testLabMarkerCodable() throws {
        let original = createLabMarker()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LabMarker.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.value, decoded.value)
        XCTAssertEqual(original.unit, decoded.unit)
        XCTAssertEqual(original.referenceMin, decoded.referenceMin)
        XCTAssertEqual(original.referenceMax, decoded.referenceMax)
        XCTAssertEqual(original.status, decoded.status)
    }

    func testLabMarkerCodingKeysMapping() throws {
        let marker = createLabMarker()

        let encoder = JSONEncoder()
        let data = try encoder.encode(marker)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify snake_case keys
        XCTAssertNotNil(jsonObject["reference_min"])
        XCTAssertNotNil(jsonObject["reference_max"])

        // Verify camelCase keys are NOT present
        XCTAssertNil(jsonObject["referenceMin"])
        XCTAssertNil(jsonObject["referenceMax"])
    }

    func testLabMarkerHashable() {
        let marker1 = createLabMarker()
        let marker2 = createLabMarker()

        var set = Set<LabMarker>()
        set.insert(marker1)
        set.insert(marker2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - MarkerStatus Tests

    func testMarkerStatusRawValues() {
        XCTAssertEqual(MarkerStatus.normal.rawValue, "normal")
        XCTAssertEqual(MarkerStatus.low.rawValue, "low")
        XCTAssertEqual(MarkerStatus.high.rawValue, "high")
        XCTAssertEqual(MarkerStatus.critical.rawValue, "critical")
    }

    func testMarkerStatusColors() {
        XCTAssertEqual(MarkerStatus.normal.color, "green")
        XCTAssertEqual(MarkerStatus.low.color, "orange")
        XCTAssertEqual(MarkerStatus.high.color, "orange")
        XCTAssertEqual(MarkerStatus.critical.color, "red")
    }

    func testMarkerStatusInitFromRawValue() {
        XCTAssertEqual(MarkerStatus(rawValue: "normal"), .normal)
        XCTAssertEqual(MarkerStatus(rawValue: "low"), .low)
        XCTAssertEqual(MarkerStatus(rawValue: "high"), .high)
        XCTAssertEqual(MarkerStatus(rawValue: "critical"), .critical)
        XCTAssertNil(MarkerStatus(rawValue: "invalid"))
    }

    func testMarkerStatusCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let statuses: [MarkerStatus] = [.normal, .low, .high, .critical]
        for status in statuses {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(MarkerStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Helpers

    private func createLabMarker(
        status: MarkerStatus = .normal
    ) -> LabMarker {
        LabMarker(
            id: UUID(),
            name: "Hemoglobin",
            value: 14.5,
            unit: "g/dL",
            referenceMin: 12.0,
            referenceMax: 17.0,
            status: status
        )
    }

    private func createLabResult() -> LabResult {
        LabResult(
            id: UUID(),
            patientId: UUID(),
            testDate: Date(),
            testType: .bloodPanel,
            results: [createLabMarker()],
            pdfUrl: "https://example.com/results.pdf",
            aiAnalysis: "All markers within normal range",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
