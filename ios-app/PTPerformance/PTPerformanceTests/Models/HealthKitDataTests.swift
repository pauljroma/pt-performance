//
//  HealthKitDataTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthKit data models
//  Tests Codable conformance and nil handling
//

import XCTest
@testable import PTPerformance

final class HealthKitDayDataModelTests: XCTestCase {

    // MARK: - Test Helpers

    private var testDate: Date {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: "2024-01-15T10:00:00Z") ?? Date()
    }

    private func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Initialization Tests

    func testHealthKitDayData_InitWithAllFields() {
        let date = testDate
        let dayData = HealthKitDayData(
            date: date,
            hrvSDNN: 65.5,
            hrvRMSSD: 72.3,
            sleepDurationMinutes: 480,
            sleepDeepMinutes: 90,
            sleepREMMinutes: 120,
            restingHeartRate: 58.0,
            activeEnergyBurned: 450.0,
            exerciseMinutes: 35,
            stepCount: nil
        )

        XCTAssertEqual(dayData.date, date)
        XCTAssertEqual(dayData.hrvSDNN, 65.5)
        XCTAssertEqual(dayData.hrvRMSSD, 72.3)
        XCTAssertEqual(dayData.sleepDurationMinutes, 480)
        XCTAssertEqual(dayData.sleepDeepMinutes, 90)
        XCTAssertEqual(dayData.sleepREMMinutes, 120)
        XCTAssertEqual(dayData.restingHeartRate, 58.0)
        XCTAssertEqual(dayData.activeEnergyBurned, 450.0)
        XCTAssertEqual(dayData.exerciseMinutes, 35)
    }

    func testHealthKitDayData_InitWithNilOptionalFields() {
        let date = testDate
        let dayData = HealthKitDayData(
            date: date,
            hrvSDNN: nil,
            hrvRMSSD: nil,
            sleepDurationMinutes: nil,
            sleepDeepMinutes: nil,
            sleepREMMinutes: nil,
            restingHeartRate: nil,
            activeEnergyBurned: nil,
            exerciseMinutes: nil,
            stepCount: nil
        )

        XCTAssertEqual(dayData.date, date)
        XCTAssertNil(dayData.hrvSDNN)
        XCTAssertNil(dayData.hrvRMSSD)
        XCTAssertNil(dayData.sleepDurationMinutes)
        XCTAssertNil(dayData.sleepDeepMinutes)
        XCTAssertNil(dayData.sleepREMMinutes)
        XCTAssertNil(dayData.restingHeartRate)
        XCTAssertNil(dayData.activeEnergyBurned)
        XCTAssertNil(dayData.exerciseMinutes)
    }

    func testHealthKitDayData_InitWithPartialFields() {
        let date = testDate
        let dayData = HealthKitDayData(
            date: date,
            hrvSDNN: 65.5,
            hrvRMSSD: nil,
            sleepDurationMinutes: 480,
            sleepDeepMinutes: nil,
            sleepREMMinutes: nil,
            restingHeartRate: 58.0,
            activeEnergyBurned: nil,
            exerciseMinutes: nil,
            stepCount: nil
        )

        XCTAssertEqual(dayData.hrvSDNN, 65.5)
        XCTAssertNil(dayData.hrvRMSSD)
        XCTAssertEqual(dayData.sleepDurationMinutes, 480)
        XCTAssertNil(dayData.sleepDeepMinutes)
        XCTAssertEqual(dayData.restingHeartRate, 58.0)
        XCTAssertNil(dayData.activeEnergyBurned)
    }

    // MARK: - Codable Encoding Tests

    func testHealthKitDayData_Encoding_AllFields() throws {
        let dayData = HealthKitDayData(
            date: testDate,
            hrvSDNN: 65.5,
            hrvRMSSD: 72.3,
            sleepDurationMinutes: 480,
            sleepDeepMinutes: 90,
            sleepREMMinutes: 120,
            restingHeartRate: 58.0,
            activeEnergyBurned: 450.0,
            exerciseMinutes: 35,
            stepCount: nil
        )

        let encoder = createEncoder()
        let data = try encoder.encode(dayData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("hrv_sdnn"))
        XCTAssertTrue(jsonString.contains("hrv_rmssd"))
        XCTAssertTrue(jsonString.contains("sleep_duration_minutes"))
        XCTAssertTrue(jsonString.contains("sleep_deep_minutes"))
        XCTAssertTrue(jsonString.contains("sleep_rem_minutes"))
        XCTAssertTrue(jsonString.contains("resting_heart_rate"))
        XCTAssertTrue(jsonString.contains("active_energy_burned"))
        XCTAssertTrue(jsonString.contains("exercise_minutes"))
    }

    func testHealthKitDayData_Encoding_UsesSnakeCaseKeys() throws {
        let dayData = HealthKitDayData(
            date: testDate,
            hrvSDNN: 65.5,
            hrvRMSSD: nil,
            sleepDurationMinutes: 480,
            sleepDeepMinutes: nil,
            sleepREMMinutes: nil,
            restingHeartRate: 58.0,
            activeEnergyBurned: nil,
            exerciseMinutes: nil,
            stepCount: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dayData)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify snake_case is used (from CodingKeys)
        XCTAssertTrue(jsonString.contains("hrv_sdnn"))
        XCTAssertTrue(jsonString.contains("sleep_duration_minutes"))
        XCTAssertTrue(jsonString.contains("resting_heart_rate"))

        // Verify camelCase is NOT used
        XCTAssertFalse(jsonString.contains("hrvSDNN"))
        XCTAssertFalse(jsonString.contains("sleepDurationMinutes"))
        XCTAssertFalse(jsonString.contains("restingHeartRate"))
    }

    // MARK: - Codable Decoding Tests

    func testHealthKitDayData_Decoding_AllFields() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 72.3,
            "hrv_rmssd": 68.5,
            "sleep_duration_minutes": 480,
            "sleep_deep_minutes": 90,
            "sleep_rem_minutes": 120,
            "resting_heart_rate": 55.0,
            "active_energy_burned": 500.0,
            "exercise_minutes": 45
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 72.3)
        XCTAssertEqual(dayData.hrvRMSSD, 68.5)
        XCTAssertEqual(dayData.sleepDurationMinutes, 480)
        XCTAssertEqual(dayData.sleepDeepMinutes, 90)
        XCTAssertEqual(dayData.sleepREMMinutes, 120)
        XCTAssertEqual(dayData.restingHeartRate, 55.0)
        XCTAssertEqual(dayData.activeEnergyBurned, 500.0)
        XCTAssertEqual(dayData.exerciseMinutes, 45)
    }

    func testHealthKitDayData_Decoding_OptionalFieldsNil() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertNil(dayData.hrvSDNN)
        XCTAssertNil(dayData.hrvRMSSD)
        XCTAssertNil(dayData.sleepDurationMinutes)
        XCTAssertNil(dayData.sleepDeepMinutes)
        XCTAssertNil(dayData.sleepREMMinutes)
        XCTAssertNil(dayData.restingHeartRate)
        XCTAssertNil(dayData.activeEnergyBurned)
        XCTAssertNil(dayData.exerciseMinutes)
    }

    func testHealthKitDayData_Decoding_PartialFields() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 65.0,
            "sleep_duration_minutes": 420,
            "resting_heart_rate": 60.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 65.0)
        XCTAssertNil(dayData.hrvRMSSD)
        XCTAssertEqual(dayData.sleepDurationMinutes, 420)
        XCTAssertNil(dayData.sleepDeepMinutes)
        XCTAssertNil(dayData.sleepREMMinutes)
        XCTAssertEqual(dayData.restingHeartRate, 60.0)
        XCTAssertNil(dayData.activeEnergyBurned)
        XCTAssertNil(dayData.exerciseMinutes)
    }

    func testHealthKitDayData_Decoding_ExplicitNullValues() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": null,
            "hrv_rmssd": null,
            "sleep_duration_minutes": null,
            "sleep_deep_minutes": null,
            "sleep_rem_minutes": null,
            "resting_heart_rate": null,
            "active_energy_burned": null,
            "exercise_minutes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertNil(dayData.hrvSDNN)
        XCTAssertNil(dayData.hrvRMSSD)
        XCTAssertNil(dayData.sleepDurationMinutes)
        XCTAssertNil(dayData.sleepDeepMinutes)
        XCTAssertNil(dayData.sleepREMMinutes)
        XCTAssertNil(dayData.restingHeartRate)
        XCTAssertNil(dayData.activeEnergyBurned)
        XCTAssertNil(dayData.exerciseMinutes)
    }

    // MARK: - Round Trip Tests

    func testHealthKitDayData_RoundTrip_AllFields() throws {
        let original = HealthKitDayData(
            date: testDate,
            hrvSDNN: 68.0,
            hrvRMSSD: 72.5,
            sleepDurationMinutes: 450,
            sleepDeepMinutes: 85,
            sleepREMMinutes: 110,
            restingHeartRate: 60.0,
            activeEnergyBurned: 350.0,
            exerciseMinutes: 30,
            stepCount: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthKitDayData.self, from: data)

        XCTAssertEqual(decoded.hrvSDNN, original.hrvSDNN)
        XCTAssertEqual(decoded.hrvRMSSD, original.hrvRMSSD)
        XCTAssertEqual(decoded.sleepDurationMinutes, original.sleepDurationMinutes)
        XCTAssertEqual(decoded.sleepDeepMinutes, original.sleepDeepMinutes)
        XCTAssertEqual(decoded.sleepREMMinutes, original.sleepREMMinutes)
        XCTAssertEqual(decoded.restingHeartRate, original.restingHeartRate)
        XCTAssertEqual(decoded.activeEnergyBurned, original.activeEnergyBurned)
        XCTAssertEqual(decoded.exerciseMinutes, original.exerciseMinutes)
    }

    func testHealthKitDayData_RoundTrip_NilFields() throws {
        let original = HealthKitDayData(
            date: testDate,
            hrvSDNN: nil,
            hrvRMSSD: nil,
            sleepDurationMinutes: nil,
            sleepDeepMinutes: nil,
            sleepREMMinutes: nil,
            restingHeartRate: nil,
            activeEnergyBurned: nil,
            exerciseMinutes: nil,
            stepCount: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthKitDayData.self, from: data)

        XCTAssertNil(decoded.hrvSDNN)
        XCTAssertNil(decoded.hrvRMSSD)
        XCTAssertNil(decoded.sleepDurationMinutes)
        XCTAssertNil(decoded.sleepDeepMinutes)
        XCTAssertNil(decoded.sleepREMMinutes)
        XCTAssertNil(decoded.restingHeartRate)
        XCTAssertNil(decoded.activeEnergyBurned)
        XCTAssertNil(decoded.exerciseMinutes)
    }

    // MARK: - Edge Case Tests

    func testHealthKitDayData_EdgeCase_ZeroValues() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 0.0,
            "hrv_rmssd": 0.0,
            "sleep_duration_minutes": 0,
            "sleep_deep_minutes": 0,
            "sleep_rem_minutes": 0,
            "resting_heart_rate": 0.0,
            "active_energy_burned": 0.0,
            "exercise_minutes": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 0.0)
        XCTAssertEqual(dayData.hrvRMSSD, 0.0)
        XCTAssertEqual(dayData.sleepDurationMinutes, 0)
        XCTAssertEqual(dayData.sleepDeepMinutes, 0)
        XCTAssertEqual(dayData.sleepREMMinutes, 0)
        XCTAssertEqual(dayData.restingHeartRate, 0.0)
        XCTAssertEqual(dayData.activeEnergyBurned, 0.0)
        XCTAssertEqual(dayData.exerciseMinutes, 0)
    }

    func testHealthKitDayData_EdgeCase_VeryHighHRV() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 200.0,
            "hrv_rmssd": 250.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 200.0)
        XCTAssertEqual(dayData.hrvRMSSD, 250.0)
    }

    func testHealthKitDayData_EdgeCase_VeryLongSleep() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "sleep_duration_minutes": 720
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.sleepDurationMinutes, 720) // 12 hours
    }

    func testHealthKitDayData_EdgeCase_HighActiveEnergy() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "active_energy_burned": 3000.0,
            "exercise_minutes": 180
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.activeEnergyBurned, 3000.0)
        XCTAssertEqual(dayData.exerciseMinutes, 180) // 3 hours
    }

    func testHealthKitDayData_EdgeCase_DecimalPrecision() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 65.123456789,
            "resting_heart_rate": 58.987654321,
            "active_energy_burned": 450.5555555
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN!, 65.123456789, accuracy: 0.0000001)
        XCTAssertEqual(dayData.restingHeartRate!, 58.987654321, accuracy: 0.0000001)
        XCTAssertEqual(dayData.activeEnergyBurned!, 450.5555555, accuracy: 0.0000001)
    }
}

// MARK: - SleepData Tests

final class SleepDataModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSleepData_InitWithAllFields() {
        let sleepData = SleepData(
            totalMinutes: 480,
            inBedMinutes: 510,
            deepMinutes: 90,
            remMinutes: 120,
            coreMinutes: 200,
            awakeMinutes: 30
        )

        XCTAssertEqual(sleepData.totalMinutes, 480)
        XCTAssertEqual(sleepData.inBedMinutes, 510)
        XCTAssertEqual(sleepData.deepMinutes, 90)
        XCTAssertEqual(sleepData.remMinutes, 120)
        XCTAssertEqual(sleepData.coreMinutes, 200)
        XCTAssertEqual(sleepData.awakeMinutes, 30)
    }

    // MARK: - Computed Property Tests

    func testSleepData_SleepEfficiency_NormalCase() {
        let sleepData = SleepData(
            totalMinutes: 450,
            inBedMinutes: 500,
            deepMinutes: 90,
            remMinutes: 110,
            coreMinutes: 200,
            awakeMinutes: 50
        )

        // sleepEfficiency = (totalMinutes - awakeMinutes) / inBedMinutes * 100
        // = (450 - 50) / 500 * 100 = 80%
        XCTAssertEqual(sleepData.sleepEfficiency, 80.0, accuracy: 0.01)
    }

    func testSleepData_SleepEfficiency_ZeroInBedMinutes() {
        let sleepData = SleepData(
            totalMinutes: 0,
            inBedMinutes: 0,
            deepMinutes: 0,
            remMinutes: 0,
            coreMinutes: 0,
            awakeMinutes: 0
        )

        XCTAssertEqual(sleepData.sleepEfficiency, 0.0)
    }

    func testSleepData_SleepEfficiency_ExcellentSleep() {
        let sleepData = SleepData(
            totalMinutes: 480,
            inBedMinutes: 490,
            deepMinutes: 100,
            remMinutes: 130,
            coreMinutes: 230,
            awakeMinutes: 10
        )

        // (480 - 10) / 490 * 100 = 95.9%
        XCTAssertGreaterThan(sleepData.sleepEfficiency, 90.0)
    }

    func testSleepData_TotalHours() {
        let sleepData = SleepData(
            totalMinutes: 480,
            inBedMinutes: 510,
            deepMinutes: 90,
            remMinutes: 120,
            coreMinutes: 200,
            awakeMinutes: 30
        )

        XCTAssertEqual(sleepData.totalHours, 8.0, accuracy: 0.01)
    }

    func testSleepData_TotalHours_FractionalHours() {
        let sleepData = SleepData(
            totalMinutes: 450, // 7.5 hours
            inBedMinutes: 480,
            deepMinutes: 85,
            remMinutes: 110,
            coreMinutes: 195,
            awakeMinutes: 30
        )

        XCTAssertEqual(sleepData.totalHours, 7.5, accuracy: 0.01)
    }

    // MARK: - Codable Tests

    func testSleepData_Encoding() throws {
        let sleepData = SleepData(
            totalMinutes: 480,
            inBedMinutes: 510,
            deepMinutes: 90,
            remMinutes: 120,
            coreMinutes: 200,
            awakeMinutes: 30
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(sleepData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("total_minutes"))
        XCTAssertTrue(jsonString.contains("in_bed_minutes"))
        XCTAssertTrue(jsonString.contains("deep_minutes"))
        XCTAssertTrue(jsonString.contains("rem_minutes"))
        XCTAssertTrue(jsonString.contains("core_minutes"))
        XCTAssertTrue(jsonString.contains("awake_minutes"))
    }

    func testSleepData_Decoding() throws {
        let json = """
        {
            "total_minutes": 450,
            "in_bed_minutes": 480,
            "deep_minutes": 85,
            "rem_minutes": 110,
            "core_minutes": 195,
            "awake_minutes": 60
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalMinutes, 450)
        XCTAssertEqual(sleepData.inBedMinutes, 480)
        XCTAssertEqual(sleepData.deepMinutes, 85)
        XCTAssertEqual(sleepData.remMinutes, 110)
        XCTAssertEqual(sleepData.coreMinutes, 195)
        XCTAssertEqual(sleepData.awakeMinutes, 60)
    }

    func testSleepData_RoundTrip() throws {
        let original = SleepData(
            totalMinutes: 420,
            inBedMinutes: 450,
            deepMinutes: 80,
            remMinutes: 100,
            coreMinutes: 180,
            awakeMinutes: 30
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SleepData.self, from: data)

        XCTAssertEqual(decoded.totalMinutes, original.totalMinutes)
        XCTAssertEqual(decoded.inBedMinutes, original.inBedMinutes)
        XCTAssertEqual(decoded.deepMinutes, original.deepMinutes)
        XCTAssertEqual(decoded.remMinutes, original.remMinutes)
        XCTAssertEqual(decoded.coreMinutes, original.coreMinutes)
        XCTAssertEqual(decoded.awakeMinutes, original.awakeMinutes)
    }
}

// MARK: - ReadinessAutoFill Tests

final class ReadinessAutoFillTests: XCTestCase {

    // MARK: - Sleep Quality From Efficiency Tests

    func testReadinessAutoFill_SleepQuality_Excellent() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(95.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(100.0), 5)
    }

    func testReadinessAutoFill_SleepQuality_Good() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(85.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.9), 4)
    }

    func testReadinessAutoFill_SleepQuality_Fair() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(75.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.9), 3)
    }

    func testReadinessAutoFill_SleepQuality_Poor() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(65.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.9), 2)
    }

    func testReadinessAutoFill_SleepQuality_VeryPoor() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(50.0), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(0.0), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.9), 1)
    }

    func testReadinessAutoFill_SleepQuality_NegativeEfficiency() {
        // Edge case: negative efficiency should return 1 (very poor)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(-10.0), 1)
    }

    func testReadinessAutoFill_SleepQuality_BoundaryValues() {
        // Test exact boundary values
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5) // >= 90
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.999), 4) // < 90
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4) // >= 80
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.999), 3) // < 80
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3) // >= 70
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.999), 2) // < 70
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2) // >= 60
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.999), 1) // < 60
    }

    // MARK: - Initialization Tests

    func testReadinessAutoFill_Init() {
        let autoFill = ReadinessAutoFill(
            suggestedSleepHours: 7.5,
            suggestedEnergyLevel: 7,
            dataSource: "apple_watch"
        )

        XCTAssertEqual(autoFill.suggestedSleepHours, 7.5)
        XCTAssertEqual(autoFill.suggestedEnergyLevel, 7)
        XCTAssertEqual(autoFill.dataSource, "apple_watch")
    }

    func testReadinessAutoFill_InitWithNilOptionals() {
        let autoFill = ReadinessAutoFill(
            suggestedSleepHours: nil,
            suggestedEnergyLevel: nil,
            dataSource: "manual"
        )

        XCTAssertNil(autoFill.suggestedSleepHours)
        XCTAssertNil(autoFill.suggestedEnergyLevel)
        XCTAssertEqual(autoFill.dataSource, "manual")
    }
}
