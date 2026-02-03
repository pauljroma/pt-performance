//
//  HealthKitServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for HealthKitService
//  Tests service initialization, published properties, computed properties, and error handling
//  Model Codable tests are in HealthKitDataTests.swift
//

import XCTest
@testable import PTPerformance

// MARK: - HealthKitError Tests

final class HealthKitErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testHealthKitError_NotAvailable_ErrorDescription() {
        let error = HealthKitError.notAvailable
        XCTAssertEqual(error.errorDescription, "HealthKit is not available on this device")
    }

    func testHealthKitError_NotAuthorized_ErrorDescription() {
        let error = HealthKitError.notAuthorized
        XCTAssertEqual(error.errorDescription, "HealthKit access has not been authorized")
    }

    func testHealthKitError_NoDataAvailable_ErrorDescription() {
        let error = HealthKitError.noDataAvailable
        XCTAssertEqual(error.errorDescription, "No health data available for the requested period")
    }

    func testHealthKitError_QueryFailed_ErrorDescription() {
        let error = HealthKitError.queryFailed("Connection timeout")
        XCTAssertEqual(error.errorDescription, "Failed to query HealthKit: Connection timeout")
    }

    func testHealthKitError_SaveFailed_ErrorDescription() {
        let error = HealthKitError.saveFailed("Database error")
        XCTAssertEqual(error.errorDescription, "Failed to save to database: Database error")
    }

    func testHealthKitError_InvalidDate_ErrorDescription() {
        let error = HealthKitError.invalidDate
        XCTAssertEqual(error.errorDescription, "Invalid date provided")
    }

    func testHealthKitError_NoAuthenticatedUser_ErrorDescription() {
        let error = HealthKitError.noAuthenticatedUser
        XCTAssertEqual(error.errorDescription, "No authenticated user found")
    }

    // MARK: - Recovery Suggestion Tests

    func testHealthKitError_NotAvailable_RecoverySuggestion() {
        let error = HealthKitError.notAvailable
        XCTAssertEqual(error.recoverySuggestion, "HealthKit requires an iPhone or Apple Watch. This feature is not available on this device.")
    }

    func testHealthKitError_NotAuthorized_RecoverySuggestion() {
        let error = HealthKitError.notAuthorized
        XCTAssertEqual(error.recoverySuggestion, "Go to Settings > Privacy > Health > PT Performance to grant access to your health data.")
    }

    func testHealthKitError_NoDataAvailable_RecoverySuggestion() {
        let error = HealthKitError.noDataAvailable
        XCTAssertEqual(error.recoverySuggestion, "Make sure you're wearing your Apple Watch and it's syncing data to your iPhone.")
    }

    func testHealthKitError_QueryFailed_RecoverySuggestion() {
        let error = HealthKitError.queryFailed("Test error")
        XCTAssertEqual(error.recoverySuggestion, "There was a problem reading your health data. Please try again.")
    }

    func testHealthKitError_SaveFailed_RecoverySuggestion() {
        let error = HealthKitError.saveFailed("Test error")
        XCTAssertEqual(error.recoverySuggestion, "Your health data couldn't be saved. Please check your connection and try again.")
    }

    func testHealthKitError_InvalidDate_RecoverySuggestion() {
        let error = HealthKitError.invalidDate
        XCTAssertEqual(error.recoverySuggestion, "Please select a valid date and try again.")
    }

    func testHealthKitError_NoAuthenticatedUser_RecoverySuggestion() {
        let error = HealthKitError.noAuthenticatedUser
        XCTAssertEqual(error.recoverySuggestion, "Please sign in to sync your health data.")
    }

    // MARK: - LocalizedError Conformance Tests

    func testHealthKitError_IsLocalizedError() {
        let errors: [HealthKitError] = [
            .notAvailable,
            .notAuthorized,
            .noDataAvailable,
            .queryFailed("test"),
            .saveFailed("test"),
            .invalidDate,
            .noAuthenticatedUser
        ]

        for error in errors {
            let localizedError: LocalizedError = error
            XCTAssertNotNil(localizedError.errorDescription, "Error \(error) should have errorDescription")
            XCTAssertNotNil(error.recoverySuggestion, "Error \(error) should have recoverySuggestion")
        }
    }
}

// MARK: - SleepData Computed Properties Tests

final class SleepDataComputedPropertiesTests: XCTestCase {

    // MARK: - Sleep Efficiency Tests

    func testSleepData_SleepEfficiency_NormalCase() {
        let sleepData = SleepData(
            totalMinutes: 420,
            inBedMinutes: 480,
            deepMinutes: 90,
            remMinutes: 108,
            coreMinutes: 192,
            awakeMinutes: 30
        )

        // Efficiency = (totalMinutes - awakeMinutes) / inBedMinutes * 100
        // = (420 - 30) / 480 * 100 = 81.25%
        let expectedEfficiency = (Double(420 - 30) / Double(480)) * 100
        XCTAssertEqual(sleepData.sleepEfficiency, expectedEfficiency, accuracy: 0.01)
    }

    func testSleepData_SleepEfficiency_ZeroInBed_ReturnsZero() {
        let sleepData = SleepData(
            totalMinutes: 0,
            inBedMinutes: 0,
            deepMinutes: nil,
            remMinutes: nil,
            coreMinutes: nil,
            awakeMinutes: nil
        )

        XCTAssertEqual(sleepData.sleepEfficiency, 0.0)
    }

    func testSleepData_SleepEfficiency_NilAwakeMinutes_TreatsAsZero() {
        let sleepData = SleepData(
            totalMinutes: 450,
            inBedMinutes: 480,
            deepMinutes: 90,
            remMinutes: 108,
            coreMinutes: 252,
            awakeMinutes: nil
        )

        // With nil awakeMinutes, treated as 0
        // (450 - 0) / 480 * 100 = 93.75%
        let expectedEfficiency = (Double(450) / Double(480)) * 100
        XCTAssertEqual(sleepData.sleepEfficiency, expectedEfficiency, accuracy: 0.01)
    }

    func testSleepData_SleepEfficiency_HighAwakeTime_LowEfficiency() {
        let sleepData = SleepData(
            totalMinutes: 300,
            inBedMinutes: 480,
            deepMinutes: 60,
            remMinutes: 60,
            coreMinutes: 100,
            awakeMinutes: 80
        )

        // (300 - 80) / 480 * 100 = 45.83%
        let expectedEfficiency = (Double(300 - 80) / Double(480)) * 100
        XCTAssertEqual(sleepData.sleepEfficiency, expectedEfficiency, accuracy: 0.01)
    }

    // MARK: - Total Hours Tests

    func testSleepData_TotalHours_WholeHours() {
        let sleepData = SleepData(
            totalMinutes: 480, // 8 hours
            inBedMinutes: 510,
            deepMinutes: nil,
            remMinutes: nil,
            coreMinutes: nil,
            awakeMinutes: nil
        )

        XCTAssertEqual(sleepData.totalHours, 8.0, accuracy: 0.01)
    }

    func testSleepData_TotalHours_FractionalHours() {
        let sleepData = SleepData(
            totalMinutes: 450, // 7.5 hours
            inBedMinutes: 510,
            deepMinutes: nil,
            remMinutes: nil,
            coreMinutes: nil,
            awakeMinutes: nil
        )

        XCTAssertEqual(sleepData.totalHours, 7.5, accuracy: 0.01)
    }

    func testSleepData_TotalHours_Zero() {
        let sleepData = SleepData(
            totalMinutes: 0,
            inBedMinutes: 0,
            deepMinutes: nil,
            remMinutes: nil,
            coreMinutes: nil,
            awakeMinutes: nil
        )

        XCTAssertEqual(sleepData.totalHours, 0.0)
    }

    func testSleepData_TotalHours_OddMinutes() {
        let sleepData = SleepData(
            totalMinutes: 427, // 7 hours 7 minutes
            inBedMinutes: 480,
            deepMinutes: nil,
            remMinutes: nil,
            coreMinutes: nil,
            awakeMinutes: nil
        )

        XCTAssertEqual(sleepData.totalHours, 427.0 / 60.0, accuracy: 0.001)
    }
}

// MARK: - ReadinessAutoFill Sleep Quality Tests

final class ReadinessAutoFillSleepQualityTests: XCTestCase {

    // MARK: - Sleep Quality From Efficiency Tests

    func testReadinessAutoFill_SleepQualityFromEfficiency_Excellent() {
        // >= 90 returns 5
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(95.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(100.0), 5)
    }

    func testReadinessAutoFill_SleepQualityFromEfficiency_Good() {
        // 80..<90 returns 4
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.9), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(85.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4)
    }

    func testReadinessAutoFill_SleepQualityFromEfficiency_Fair() {
        // 70..<80 returns 3
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.9), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(75.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3)
    }

    func testReadinessAutoFill_SleepQualityFromEfficiency_Poor() {
        // 60..<70 returns 2
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.9), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(65.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2)
    }

    func testReadinessAutoFill_SleepQualityFromEfficiency_VeryPoor() {
        // < 60 returns 1
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.9), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(50.0), 1)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(0.0), 1)
    }

    func testReadinessAutoFill_SleepQualityFromEfficiency_NegativeValue() {
        // Negative values (edge case) should return 1
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(-10.0), 1)
    }

    // MARK: - Boundary Tests

    func testReadinessAutoFill_SleepQuality_BoundaryAt90() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(90.0), 5)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(89.999), 4)
    }

    func testReadinessAutoFill_SleepQuality_BoundaryAt80() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(80.0), 4)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(79.999), 3)
    }

    func testReadinessAutoFill_SleepQuality_BoundaryAt70() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(70.0), 3)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(69.999), 2)
    }

    func testReadinessAutoFill_SleepQuality_BoundaryAt60() {
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(60.0), 2)
        XCTAssertEqual(ReadinessAutoFill.sleepQualityFromEfficiency(59.999), 1)
    }
}

// MARK: - ReadinessAutoFill Initialization Tests

final class ReadinessAutoFillInitializationTests: XCTestCase {

    func testReadinessAutoFill_InitWithAllValues() {
        let autoFill = ReadinessAutoFill(
            suggestedSleepHours: 7.5,
            suggestedEnergyLevel: 8,
            dataSource: "apple_watch"
        )

        XCTAssertEqual(autoFill.suggestedSleepHours, 7.5)
        XCTAssertEqual(autoFill.suggestedEnergyLevel, 8)
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

    func testReadinessAutoFill_DataSourceValues() {
        let appleWatchSource = ReadinessAutoFill(
            suggestedSleepHours: 7.0,
            suggestedEnergyLevel: 7,
            dataSource: "apple_watch"
        )

        let manualSource = ReadinessAutoFill(
            suggestedSleepHours: nil,
            suggestedEnergyLevel: nil,
            dataSource: "manual"
        )

        XCTAssertEqual(appleWatchSource.dataSource, "apple_watch")
        XCTAssertEqual(manualSource.dataSource, "manual")
    }
}

// MARK: - HealthKitDayData CodingKeys Tests

final class HealthKitDayDataCodingKeysTests: XCTestCase {

    func testHealthKitDayData_EncodesWithSnakeCaseKeys() throws {
        let dayData = HealthKitDayData(
            date: Date(),
            hrvSDNN: 65.0,
            hrvRMSSD: 72.0,
            sleepDurationMinutes: 450,
            sleepDeepMinutes: 90,
            sleepREMMinutes: 108,
            restingHeartRate: 58.0,
            activeEnergyBurned: 450.0,
            exerciseMinutes: 35,
            stepCount: 8500
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dayData)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify snake_case keys are used
        XCTAssertTrue(jsonString.contains("hrv_sdnn"))
        XCTAssertTrue(jsonString.contains("hrv_rmssd"))
        XCTAssertTrue(jsonString.contains("sleep_duration_minutes"))
        XCTAssertTrue(jsonString.contains("sleep_deep_minutes"))
        XCTAssertTrue(jsonString.contains("sleep_rem_minutes"))
        XCTAssertTrue(jsonString.contains("resting_heart_rate"))
        XCTAssertTrue(jsonString.contains("active_energy_burned"))
        XCTAssertTrue(jsonString.contains("exercise_minutes"))
        XCTAssertTrue(jsonString.contains("step_count"))

        // Verify camelCase is NOT used
        XCTAssertFalse(jsonString.contains("hrvSDNN"))
        XCTAssertFalse(jsonString.contains("sleepDurationMinutes"))
        XCTAssertFalse(jsonString.contains("restingHeartRate"))
        XCTAssertFalse(jsonString.contains("stepCount"))
    }

    func testHealthKitDayData_DecodesFromSnakeCaseKeys() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 65.5,
            "hrv_rmssd": 72.3,
            "sleep_duration_minutes": 450,
            "sleep_deep_minutes": 90,
            "sleep_rem_minutes": 108,
            "resting_heart_rate": 58.0,
            "active_energy_burned": 450.0,
            "exercise_minutes": 35,
            "step_count": 8500
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 65.5)
        XCTAssertEqual(dayData.hrvRMSSD, 72.3)
        XCTAssertEqual(dayData.sleepDurationMinutes, 450)
        XCTAssertEqual(dayData.sleepDeepMinutes, 90)
        XCTAssertEqual(dayData.sleepREMMinutes, 108)
        XCTAssertEqual(dayData.restingHeartRate, 58.0)
        XCTAssertEqual(dayData.activeEnergyBurned, 450.0)
        XCTAssertEqual(dayData.exerciseMinutes, 35)
        XCTAssertEqual(dayData.stepCount, 8500)
    }
}

// MARK: - SleepData CodingKeys Tests

final class SleepDataCodingKeysTests: XCTestCase {

    func testSleepData_EncodesWithSnakeCaseKeys() throws {
        let sleepData = SleepData(
            totalMinutes: 450,
            inBedMinutes: 510,
            deepMinutes: 90,
            remMinutes: 108,
            coreMinutes: 252,
            awakeMinutes: 30
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(sleepData)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify snake_case keys are used
        XCTAssertTrue(jsonString.contains("total_minutes"))
        XCTAssertTrue(jsonString.contains("in_bed_minutes"))
        XCTAssertTrue(jsonString.contains("deep_minutes"))
        XCTAssertTrue(jsonString.contains("rem_minutes"))
        XCTAssertTrue(jsonString.contains("core_minutes"))
        XCTAssertTrue(jsonString.contains("awake_minutes"))

        // Verify camelCase is NOT used
        XCTAssertFalse(jsonString.contains("totalMinutes"))
        XCTAssertFalse(jsonString.contains("inBedMinutes"))
        XCTAssertFalse(jsonString.contains("deepMinutes"))
    }

    func testSleepData_DecodesFromSnakeCaseKeys() throws {
        let json = """
        {
            "total_minutes": 450,
            "in_bed_minutes": 510,
            "deep_minutes": 90,
            "rem_minutes": 108,
            "core_minutes": 252,
            "awake_minutes": 30
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalMinutes, 450)
        XCTAssertEqual(sleepData.inBedMinutes, 510)
        XCTAssertEqual(sleepData.deepMinutes, 90)
        XCTAssertEqual(sleepData.remMinutes, 108)
        XCTAssertEqual(sleepData.coreMinutes, 252)
        XCTAssertEqual(sleepData.awakeMinutes, 30)
    }
}

// MARK: - Sample Data Tests

#if DEBUG
final class HealthKitSampleDataTests: XCTestCase {

    func testHealthKitDayData_SampleValues() {
        let sample = HealthKitDayData.sample

        XCTAssertEqual(sample.hrvSDNN, 65.5)
        XCTAssertNil(sample.hrvRMSSD, "Apple Watch provides SDNN, not RMSSD")
        XCTAssertEqual(sample.sleepDurationMinutes, 450)
        XCTAssertEqual(sample.sleepDeepMinutes, 90)
        XCTAssertEqual(sample.sleepREMMinutes, 108)
        XCTAssertEqual(sample.restingHeartRate, 58.0)
        XCTAssertEqual(sample.activeEnergyBurned, 450.0)
        XCTAssertEqual(sample.exerciseMinutes, 35)
        XCTAssertEqual(sample.stepCount, 8500)
    }

    func testSleepData_SampleValues() {
        let sample = SleepData.sample

        XCTAssertEqual(sample.totalMinutes, 450)
        XCTAssertEqual(sample.inBedMinutes, 510)
        XCTAssertEqual(sample.deepMinutes, 90)
        XCTAssertEqual(sample.remMinutes, 108)
        XCTAssertEqual(sample.coreMinutes, 252)
        XCTAssertEqual(sample.awakeMinutes, 30)
    }

    func testReadinessAutoFill_SampleValues() {
        let sample = ReadinessAutoFill.sample

        XCTAssertEqual(sample.suggestedSleepHours, 7.5)
        XCTAssertEqual(sample.suggestedEnergyLevel, 8)
        XCTAssertEqual(sample.dataSource, "apple_watch")
    }
}
#endif

// MARK: - HealthKitDayData Nil Fields Tests

final class HealthKitDayDataNilFieldsTests: XCTestCase {

    func testHealthKitDayData_AllFieldsNil() throws {
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
        XCTAssertNil(dayData.stepCount)
    }

    func testHealthKitDayData_ExplicitNullValues() throws {
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
            "exercise_minutes": null,
            "step_count": null
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
        XCTAssertNil(dayData.stepCount)
    }
}

// MARK: - SleepData Nil Fields Tests

final class SleepDataNilFieldsTests: XCTestCase {

    func testSleepData_OptionalFieldsNil() throws {
        let json = """
        {
            "total_minutes": 420,
            "in_bed_minutes": 480
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalMinutes, 420)
        XCTAssertEqual(sleepData.inBedMinutes, 480)
        XCTAssertNil(sleepData.deepMinutes)
        XCTAssertNil(sleepData.remMinutes)
        XCTAssertNil(sleepData.coreMinutes)
        XCTAssertNil(sleepData.awakeMinutes)
    }

    func testSleepData_ExplicitNullValues() throws {
        let json = """
        {
            "total_minutes": 420,
            "in_bed_minutes": 480,
            "deep_minutes": null,
            "rem_minutes": null,
            "core_minutes": null,
            "awake_minutes": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sleepData = try decoder.decode(SleepData.self, from: json)

        XCTAssertEqual(sleepData.totalMinutes, 420)
        XCTAssertEqual(sleepData.inBedMinutes, 480)
        XCTAssertNil(sleepData.deepMinutes)
        XCTAssertNil(sleepData.remMinutes)
        XCTAssertNil(sleepData.coreMinutes)
        XCTAssertNil(sleepData.awakeMinutes)
    }
}

// MARK: - Edge Case Tests

final class HealthKitEdgeCaseTests: XCTestCase {

    func testHealthKitDayData_ZeroValues() throws {
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
            "exercise_minutes": 0,
            "step_count": 0
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
        XCTAssertEqual(dayData.stepCount, 0)
    }

    func testHealthKitDayData_VeryHighHRV() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "hrv_sdnn": 200.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.hrvSDNN, 200.0)
    }

    func testHealthKitDayData_VeryLongSleep() throws {
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

    func testHealthKitDayData_HighActivityValues() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "active_energy_burned": 3000.0,
            "exercise_minutes": 180,
            "step_count": 25000
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dayData = try decoder.decode(HealthKitDayData.self, from: json)

        XCTAssertEqual(dayData.activeEnergyBurned, 3000.0)
        XCTAssertEqual(dayData.exerciseMinutes, 180)
        XCTAssertEqual(dayData.stepCount, 25000)
    }

    func testSleepData_ZeroValues_SleepEfficiencyIsZero() {
        let sleepData = SleepData(
            totalMinutes: 0,
            inBedMinutes: 0,
            deepMinutes: 0,
            remMinutes: 0,
            coreMinutes: 0,
            awakeMinutes: 0
        )

        XCTAssertEqual(sleepData.sleepEfficiency, 0.0)
        XCTAssertEqual(sleepData.totalHours, 0.0)
    }
}

// MARK: - Round Trip Tests

final class HealthKitRoundTripTests: XCTestCase {

    func testHealthKitDayData_RoundTrip_AllFields() throws {
        let original = HealthKitDayData(
            date: Date(),
            hrvSDNN: 68.0,
            hrvRMSSD: 74.5,
            sleepDurationMinutes: 450,
            sleepDeepMinutes: 85,
            sleepREMMinutes: 110,
            restingHeartRate: 60.0,
            activeEnergyBurned: 350.0,
            exerciseMinutes: 30,
            stepCount: 9500
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
        XCTAssertEqual(decoded.stepCount, original.stepCount)
    }

    func testHealthKitDayData_RoundTrip_NilFields() throws {
        let original = HealthKitDayData(
            date: Date(),
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
        XCTAssertNil(decoded.stepCount)
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
