//
//  HealthKitServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthKitService
//  Tests model Codable encoding/decoding, computed properties, and business logic
//

import XCTest
@testable import PTPerformance

// MARK: - HealthKitDayData Tests

final class HealthKitDayDataTests: XCTestCase {

    // MARK: - Codable Tests

    func testHealthKitDayData_Encoding_AllFields() throws {
        let date = Date()
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 8.5,
            asleepDuration: 7.5,
            remDuration: 1.8,
            deepSleepDuration: 1.5,
            lightSleepDuration: 4.2,
            awakeDuration: 0.5,
            sleepEfficiency: 88.2
        )

        let dayData = HealthKitDayData(
            date: date,
            hrv: 65.5,
            restingHeartRate: 58.0,
            sleepDuration: 7.5,
            sleepData: sleepData,
            activeEnergyBurned: 450.0,
            appleExerciseTime: 35.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dayData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"hrv\":65.5"))
        XCTAssertTrue(jsonString.contains("\"resting_heart_rate\":58"))
        XCTAssertTrue(jsonString.contains("\"sleep_duration\":7.5"))
        XCTAssertTrue(jsonString.contains("\"active_energy_burned\":450"))
        XCTAssertTrue(jsonString.contains("\"apple_exercise_time\":35"))
    }

    func testHealthKitDayData_Decoding_AllFields() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv": 72.3,
            "resting_heart_rate": 55.0,
            "sleep_duration": 8.0,
            "sleep_data": {
                "total_duration": 8.0,
                "in_bed_duration": 8.5,
                "asleep_duration": 7.5,
                "rem_duration": 2.0,
                "deep_sleep_duration": 1.5,
                "light_sleep_duration": 4.0,
                "awake_duration": 0.5,
                "sleep_efficiency": 88.0
            },
            "active_energy_burned": 500.0,
            "apple_exercise_time": 45.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrv, 72.3)
        XCTAssertEqual(dayData.restingHeartRate, 55.0)
        XCTAssertEqual(dayData.sleepDuration, 8.0)
        XCTAssertEqual(dayData.activeEnergyBurned, 500.0)
        XCTAssertEqual(dayData.appleExerciseTime, 45.0)
        XCTAssertNotNil(dayData.sleepData)
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

        XCTAssertNil(dayData.hrv)
        XCTAssertNil(dayData.restingHeartRate)
        XCTAssertNil(dayData.sleepDuration)
        XCTAssertNil(dayData.sleepData)
        XCTAssertNil(dayData.activeEnergyBurned)
        XCTAssertNil(dayData.appleExerciseTime)
    }

    func testHealthKitDayData_RoundTrip() throws {
        let original = HealthKitDayData(
            date: Date(),
            hrv: 68.0,
            restingHeartRate: 60.0,
            sleepDuration: 7.0,
            sleepData: nil,
            activeEnergyBurned: 350.0,
            appleExerciseTime: 30.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HealthKitDayData.self, from: data)

        XCTAssertEqual(decoded.hrv, original.hrv)
        XCTAssertEqual(decoded.restingHeartRate, original.restingHeartRate)
        XCTAssertEqual(decoded.sleepDuration, original.sleepDuration)
        XCTAssertEqual(decoded.activeEnergyBurned, original.activeEnergyBurned)
        XCTAssertEqual(decoded.appleExerciseTime, original.appleExerciseTime)
    }
}

// MARK: - SleepData Tests

final class SleepDataTests: XCTestCase {

    // MARK: - Codable Tests

    func testSleepData_Encoding_AllFields() throws {
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 8.5,
            asleepDuration: 7.5,
            remDuration: 1.8,
            deepSleepDuration: 1.5,
            lightSleepDuration: 4.2,
            awakeDuration: 0.5,
            sleepEfficiency: 88.2
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(sleepData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"total_duration\":8"))
        XCTAssertTrue(jsonString.contains("\"in_bed_duration\":8.5"))
        XCTAssertTrue(jsonString.contains("\"asleep_duration\":7.5"))
        XCTAssertTrue(jsonString.contains("\"rem_duration\":1.8"))
        XCTAssertTrue(jsonString.contains("\"deep_sleep_duration\":1.5"))
        XCTAssertTrue(jsonString.contains("\"sleep_efficiency\":88.2"))
    }

    func testSleepData_Decoding_AllFields() throws {
        let json = """
        {
            "total_duration": 7.5,
            "in_bed_duration": 8.0,
            "asleep_duration": 7.0,
            "rem_duration": 1.5,
            "deep_sleep_duration": 1.2,
            "light_sleep_duration": 4.3,
            "awake_duration": 0.5,
            "sleep_efficiency": 87.5
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalDuration, 7.5)
        XCTAssertEqual(sleepData.inBedDuration, 8.0)
        XCTAssertEqual(sleepData.asleepDuration, 7.0)
        XCTAssertEqual(sleepData.remDuration, 1.5)
        XCTAssertEqual(sleepData.deepSleepDuration, 1.2)
        XCTAssertEqual(sleepData.lightSleepDuration, 4.3)
        XCTAssertEqual(sleepData.awakeDuration, 0.5)
        XCTAssertEqual(sleepData.sleepEfficiency, 87.5)
    }

    func testSleepData_Decoding_OptionalFieldsNil() throws {
        let json = """
        {
            "total_duration": 7.0,
            "in_bed_duration": 7.5,
            "asleep_duration": 6.5
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalDuration, 7.0)
        XCTAssertEqual(sleepData.inBedDuration, 7.5)
        XCTAssertEqual(sleepData.asleepDuration, 6.5)
        XCTAssertNil(sleepData.remDuration)
        XCTAssertNil(sleepData.deepSleepDuration)
        XCTAssertNil(sleepData.lightSleepDuration)
        XCTAssertNil(sleepData.awakeDuration)
        XCTAssertNil(sleepData.sleepEfficiency)
    }

    // MARK: - Computed Properties Tests

    func testSleepData_CalculatedEfficiency_NormalValues() {
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 8.0,
            asleepDuration: 7.2,
            remDuration: nil,
            deepSleepDuration: nil,
            lightSleepDuration: nil,
            awakeDuration: nil,
            sleepEfficiency: nil
        )

        // 7.2 / 8.0 * 100 = 90%
        XCTAssertEqual(sleepData.calculatedEfficiency, 90.0, accuracy: 0.01)
    }

    func testSleepData_CalculatedEfficiency_ZeroInBed() {
        let sleepData = SleepData(
            totalDuration: 0.0,
            inBedDuration: 0.0,
            asleepDuration: 0.0,
            remDuration: nil,
            deepSleepDuration: nil,
            lightSleepDuration: nil,
            awakeDuration: nil,
            sleepEfficiency: nil
        )

        XCTAssertEqual(sleepData.calculatedEfficiency, 0.0)
    }

    func testSleepData_CalculatedEfficiency_FullEfficiency() {
        let sleepData = SleepData(
            totalDuration: 7.0,
            inBedDuration: 7.0,
            asleepDuration: 7.0,
            remDuration: nil,
            deepSleepDuration: nil,
            lightSleepDuration: nil,
            awakeDuration: nil,
            sleepEfficiency: nil
        )

        XCTAssertEqual(sleepData.calculatedEfficiency, 100.0, accuracy: 0.01)
    }

    func testSleepData_CalculatedEfficiency_LowEfficiency() {
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 10.0,
            asleepDuration: 5.5,
            remDuration: nil,
            deepSleepDuration: nil,
            lightSleepDuration: nil,
            awakeDuration: nil,
            sleepEfficiency: nil
        )

        // 5.5 / 10.0 * 100 = 55%
        XCTAssertEqual(sleepData.calculatedEfficiency, 55.0, accuracy: 0.01)
    }

    func testSleepData_RoundTrip() throws {
        let original = SleepData(
            totalDuration: 7.5,
            inBedDuration: 8.0,
            asleepDuration: 7.0,
            remDuration: 1.5,
            deepSleepDuration: 1.0,
            lightSleepDuration: 4.5,
            awakeDuration: 0.5,
            sleepEfficiency: 87.5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SleepData.self, from: data)

        XCTAssertEqual(decoded.totalDuration, original.totalDuration)
        XCTAssertEqual(decoded.inBedDuration, original.inBedDuration)
        XCTAssertEqual(decoded.asleepDuration, original.asleepDuration)
        XCTAssertEqual(decoded.remDuration, original.remDuration)
        XCTAssertEqual(decoded.deepSleepDuration, original.deepSleepDuration)
        XCTAssertEqual(decoded.sleepEfficiency, original.sleepEfficiency)
    }
}

// MARK: - ReadinessAutoFill Tests

final class ReadinessAutoFillTests: XCTestCase {

    // MARK: - Sleep Quality Calculation Tests

    func testSleepQualityFromEfficiency_Excellent() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(95.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(100.0), 5)
    }

    func testSleepQualityFromEfficiency_Good() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.9), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(85.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4)
    }

    func testSleepQualityFromEfficiency_Fair() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.9), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(75.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3)
    }

    func testSleepQualityFromEfficiency_Poor() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.9), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(65.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2)
    }

    func testSleepQualityFromEfficiency_VeryPoor() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.9), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(50.0), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(0.0), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(-10.0), 1)
    }

    func testSleepQualityFromEfficiency_BoundaryAt90() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.99), 4)
    }

    func testSleepQualityFromEfficiency_BoundaryAt80() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.99), 3)
    }

    func testSleepQualityFromEfficiency_BoundaryAt70() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.99), 2)
    }

    func testSleepQualityFromEfficiency_BoundaryAt60() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.99), 1)
    }

    // MARK: - Initialization Tests

    func testReadinessAutoFill_Initialization() {
        let autoFill = ReadinessAutoFill(
            sleepHours: 7.5,
            sleepQuality: 4,
            hrvValue: 65.5,
            restingHeartRate: 58.0,
            dataSource: "HealthKit",
            lastSyncDate: Date()
        )

        XCTAssertEqual(autoFill.sleepHours, 7.5)
        XCTAssertEqual(autoFill.sleepQuality, 4)
        XCTAssertEqual(autoFill.hrvValue, 65.5)
        XCTAssertEqual(autoFill.restingHeartRate, 58.0)
        XCTAssertEqual(autoFill.dataSource, "HealthKit")
        XCTAssertNotNil(autoFill.lastSyncDate)
    }

    func testReadinessAutoFill_NilValues() {
        let autoFill = ReadinessAutoFill(
            sleepHours: nil,
            sleepQuality: nil,
            hrvValue: nil,
            restingHeartRate: nil,
            dataSource: "AppleWatch",
            lastSyncDate: nil
        )

        XCTAssertNil(autoFill.sleepHours)
        XCTAssertNil(autoFill.sleepQuality)
        XCTAssertNil(autoFill.hrvValue)
        XCTAssertNil(autoFill.restingHeartRate)
        XCTAssertEqual(autoFill.dataSource, "AppleWatch")
        XCTAssertNil(autoFill.lastSyncDate)
    }
}

// MARK: - HealthKitError Tests

final class HealthKitErrorTests: XCTestCase {

    func testErrorDescription_NotAvailable() {
        let error = HealthKitError.notAvailable
        XCTAssertEqual(error.errorDescription, "HealthKit is not available on this device")
    }

    func testErrorDescription_NotAuthorized() {
        let error = HealthKitError.notAuthorized
        XCTAssertEqual(error.errorDescription, "HealthKit access has not been authorized")
    }

    func testErrorDescription_NoDataAvailable() {
        let error = HealthKitError.noDataAvailable
        XCTAssertEqual(error.errorDescription, "No health data available for the requested period")
    }

    func testErrorDescription_QueryFailed() {
        let error = HealthKitError.queryFailed("Connection timeout")
        XCTAssertEqual(error.errorDescription, "Failed to query HealthKit: Connection timeout")
    }

    func testErrorDescription_SaveFailed() {
        let error = HealthKitError.saveFailed("Database error")
        XCTAssertEqual(error.errorDescription, "Failed to save to database: Database error")
    }

    func testErrorDescription_InvalidDate() {
        let error = HealthKitError.invalidDate
        XCTAssertEqual(error.errorDescription, "Invalid date provided")
    }

    func testError_IsLocalizedError() {
        let error: LocalizedError = HealthKitError.notAvailable
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class HealthKitSampleDataTests: XCTestCase {

    func testHealthKitDayData_Sample() {
        let sample = HealthKitDayData.sample

        XCTAssertEqual(sample.hrv, 65.5)
        XCTAssertEqual(sample.restingHeartRate, 58.0)
        XCTAssertEqual(sample.sleepDuration, 7.5)
        XCTAssertEqual(sample.activeEnergyBurned, 450.0)
        XCTAssertEqual(sample.appleExerciseTime, 35.0)
        XCTAssertNotNil(sample.sleepData)
    }

    func testSleepData_Sample() {
        let sample = SleepData.sample

        XCTAssertEqual(sample.totalDuration, 8.0)
        XCTAssertEqual(sample.inBedDuration, 8.5)
        XCTAssertEqual(sample.asleepDuration, 7.5)
        XCTAssertEqual(sample.remDuration, 1.8)
        XCTAssertEqual(sample.deepSleepDuration, 1.5)
        XCTAssertEqual(sample.lightSleepDuration, 4.2)
        XCTAssertEqual(sample.awakeDuration, 0.5)
        XCTAssertEqual(sample.sleepEfficiency, 88.2)
    }

    func testReadinessAutoFill_Sample() {
        let sample = ReadinessAutoFill.sample

        XCTAssertEqual(sample.sleepHours, 7.5)
        XCTAssertEqual(sample.sleepQuality, 4)
        XCTAssertEqual(sample.hrvValue, 65.5)
        XCTAssertEqual(sample.restingHeartRate, 58.0)
        XCTAssertEqual(sample.dataSource, "HealthKit")
        XCTAssertNotNil(sample.lastSyncDate)
    }
}
#endif

// MARK: - Edge Cases and Boundary Tests

final class HealthKitEdgeCaseTests: XCTestCase {

    func testSleepData_ExtremeValues() throws {
        let json = """
        {
            "total_duration": 24.0,
            "in_bed_duration": 24.0,
            "asleep_duration": 20.0,
            "rem_duration": 5.0,
            "deep_sleep_duration": 5.0,
            "light_sleep_duration": 10.0,
            "awake_duration": 4.0,
            "sleep_efficiency": 83.33
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalDuration, 24.0)
        XCTAssertEqual(sleepData.asleepDuration, 20.0)
    }

    func testSleepData_ZeroValues() throws {
        let json = """
        {
            "total_duration": 0.0,
            "in_bed_duration": 0.0,
            "asleep_duration": 0.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalDuration, 0.0)
        XCTAssertEqual(sleepData.calculatedEfficiency, 0.0)
    }

    func testHealthKitDayData_NegativeHRV() throws {
        // Edge case: negative HRV should still decode
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv": -5.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrv, -5.0)
    }

    func testHealthKitDayData_VeryHighHRV() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv": 200.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrv, 200.0)
    }

    func testSleepEfficiency_Above100() {
        // Edge case: calculated efficiency exceeding 100%
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 6.0,
            asleepDuration: 8.0, // More asleep than in bed (data error)
            remDuration: nil,
            deepSleepDuration: nil,
            lightSleepDuration: nil,
            awakeDuration: nil,
            sleepEfficiency: nil
        )

        // 8.0 / 6.0 * 100 = 133.33%
        XCTAssertEqual(sleepData.calculatedEfficiency, 133.33, accuracy: 0.01)
    }

    func testSleepQuality_EdgeValues() {
        // Test exact boundary values
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.9999), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0001), 5)
    }
}

// MARK: - CodingKeys Tests

final class HealthKitCodingKeysTests: XCTestCase {

    func testHealthKitDayData_UsesSnakeCaseKeys() throws {
        let dayData = HealthKitDayData(
            date: Date(),
            hrv: 65.0,
            restingHeartRate: 58.0,
            sleepDuration: 7.5,
            sleepData: nil,
            activeEnergyBurned: 450.0,
            appleExerciseTime: 35.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dayData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("resting_heart_rate"))
        XCTAssertTrue(jsonString.contains("sleep_duration"))
        XCTAssertTrue(jsonString.contains("active_energy_burned"))
        XCTAssertTrue(jsonString.contains("apple_exercise_time"))
        XCTAssertFalse(jsonString.contains("restingHeartRate"))
        XCTAssertFalse(jsonString.contains("sleepDuration"))
    }

    func testSleepData_UsesSnakeCaseKeys() throws {
        let sleepData = SleepData(
            totalDuration: 8.0,
            inBedDuration: 8.5,
            asleepDuration: 7.5,
            remDuration: 1.5,
            deepSleepDuration: 1.5,
            lightSleepDuration: 4.5,
            awakeDuration: 0.5,
            sleepEfficiency: 88.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(sleepData)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("total_duration"))
        XCTAssertTrue(jsonString.contains("in_bed_duration"))
        XCTAssertTrue(jsonString.contains("asleep_duration"))
        XCTAssertTrue(jsonString.contains("rem_duration"))
        XCTAssertTrue(jsonString.contains("deep_sleep_duration"))
        XCTAssertTrue(jsonString.contains("sleep_efficiency"))
    }
}
