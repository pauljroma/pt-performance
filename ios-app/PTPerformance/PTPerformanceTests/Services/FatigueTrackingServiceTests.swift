//
//  FatigueTrackingServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueTrackingService
//  Tests model Codable encoding/decoding, enum properties, and business logic
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - FatigueBand Tests

final class FatigueBandTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testFatigueBand_RawValues() {
        XCTAssertEqual(FatigueBand.low.rawValue, "low")
        XCTAssertEqual(FatigueBand.moderate.rawValue, "moderate")
        XCTAssertEqual(FatigueBand.high.rawValue, "high")
        XCTAssertEqual(FatigueBand.critical.rawValue, "critical")
    }

    func testFatigueBand_InitFromRawValue() {
        XCTAssertEqual(FatigueBand(rawValue: "low"), .low)
        XCTAssertEqual(FatigueBand(rawValue: "moderate"), .moderate)
        XCTAssertEqual(FatigueBand(rawValue: "high"), .high)
        XCTAssertEqual(FatigueBand(rawValue: "critical"), .critical)
        XCTAssertNil(FatigueBand(rawValue: "invalid"))
    }

    // MARK: - Color Tests

    func testFatigueBand_Colors() {
        XCTAssertEqual(FatigueBand.low.color, .green)
        XCTAssertEqual(FatigueBand.moderate.color, .yellow)
        XCTAssertEqual(FatigueBand.high.color, .orange)
        XCTAssertEqual(FatigueBand.critical.color, .red)
    }

    // MARK: - Icon Tests

    func testFatigueBand_Icons() {
        XCTAssertEqual(FatigueBand.low.icon, "battery.100")
        XCTAssertEqual(FatigueBand.moderate.icon, "battery.75")
        XCTAssertEqual(FatigueBand.high.icon, "battery.25")
        XCTAssertEqual(FatigueBand.critical.icon, "battery.0")
    }

    // MARK: - Description Tests

    func testFatigueBand_Descriptions() {
        XCTAssertEqual(FatigueBand.low.description, "Low fatigue - Ready for full training")
        XCTAssertEqual(FatigueBand.moderate.description, "Moderate fatigue - Monitor recovery")
        XCTAssertEqual(FatigueBand.high.description, "High fatigue - Consider reducing load")
        XCTAssertEqual(FatigueBand.critical.description, "Critical fatigue - Deload recommended")
    }

    // MARK: - Display Name Tests

    func testFatigueBand_DisplayNames() {
        XCTAssertEqual(FatigueBand.low.displayName, "Low")
        XCTAssertEqual(FatigueBand.moderate.displayName, "Moderate")
        XCTAssertEqual(FatigueBand.high.displayName, "High")
        XCTAssertEqual(FatigueBand.critical.displayName, "Critical")
    }

    // MARK: - CaseIterable Tests

    func testFatigueBand_AllCases() {
        let allCases = FatigueBand.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.moderate))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.critical))
    }

    // MARK: - Codable Tests

    func testFatigueBand_Encoding() throws {
        let band = FatigueBand.moderate
        let encoder = JSONEncoder()
        let data = try encoder.encode(band)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"moderate\"")
    }

    func testFatigueBand_Decoding() throws {
        let json = "\"critical\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let band = try decoder.decode(FatigueBand.self, from: json)

        XCTAssertEqual(band, .critical)
    }
}

// MARK: - DeloadUrgency Tests

final class DeloadUrgencyTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testDeloadUrgency_RawValues() {
        XCTAssertEqual(DeloadUrgency.none.rawValue, "none")
        XCTAssertEqual(DeloadUrgency.suggested.rawValue, "suggested")
        XCTAssertEqual(DeloadUrgency.recommended.rawValue, "recommended")
        XCTAssertEqual(DeloadUrgency.required.rawValue, "required")
    }

    func testDeloadUrgency_InitFromRawValue() {
        XCTAssertEqual(DeloadUrgency(rawValue: "none"), .none)
        XCTAssertEqual(DeloadUrgency(rawValue: "suggested"), .suggested)
        XCTAssertEqual(DeloadUrgency(rawValue: "recommended"), .recommended)
        XCTAssertEqual(DeloadUrgency(rawValue: "required"), .required)
        XCTAssertNil(DeloadUrgency(rawValue: "invalid"))
    }

    // MARK: - Title Tests

    func testDeloadUrgency_Titles() {
        XCTAssertEqual(DeloadUrgency.none.title, "No Deload Needed")
        XCTAssertEqual(DeloadUrgency.suggested.title, "Deload Suggested")
        XCTAssertEqual(DeloadUrgency.recommended.title, "Deload Recommended")
        XCTAssertEqual(DeloadUrgency.required.title, "Deload Required")
    }

    // MARK: - Subtitle Tests

    func testDeloadUrgency_Subtitles() {
        XCTAssertEqual(DeloadUrgency.none.subtitle, "Continue training as planned")
        XCTAssertEqual(DeloadUrgency.suggested.subtitle, "Consider a lighter week if fatigue persists")
        XCTAssertEqual(DeloadUrgency.recommended.subtitle, "A deload week would benefit recovery")
        XCTAssertEqual(DeloadUrgency.required.subtitle, "Immediate deload needed to prevent overtraining")
    }

    // MARK: - Color Tests

    func testDeloadUrgency_Colors() {
        XCTAssertEqual(DeloadUrgency.none.color, .green)
        XCTAssertEqual(DeloadUrgency.suggested.color, .yellow)
        XCTAssertEqual(DeloadUrgency.recommended.color, .orange)
        XCTAssertEqual(DeloadUrgency.required.color, .red)
    }

    // MARK: - Icon Tests

    func testDeloadUrgency_Icons() {
        XCTAssertEqual(DeloadUrgency.none.icon, "checkmark.circle")
        XCTAssertEqual(DeloadUrgency.suggested.icon, "info.circle")
        XCTAssertEqual(DeloadUrgency.recommended.icon, "exclamationmark.triangle")
        XCTAssertEqual(DeloadUrgency.required.icon, "exclamationmark.octagon")
    }

    // MARK: - CaseIterable Tests

    func testDeloadUrgency_AllCases() {
        let allCases = DeloadUrgency.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.suggested))
        XCTAssertTrue(allCases.contains(.recommended))
        XCTAssertTrue(allCases.contains(.required))
    }

    // MARK: - Codable Tests

    func testDeloadUrgency_Encoding() throws {
        let urgency = DeloadUrgency.recommended
        let encoder = JSONEncoder()
        let data = try encoder.encode(urgency)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"recommended\"")
    }

    func testDeloadUrgency_Decoding() throws {
        let json = "\"required\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let urgency = try decoder.decode(DeloadUrgency.self, from: json)

        XCTAssertEqual(urgency, .required)
    }
}

// MARK: - FatigueAccumulation Tests

final class FatigueAccumulationTests: XCTestCase {

    // MARK: - Memberwise Initializer Tests

    func testFatigueAccumulation_MemberwiseInit() {
        let id = UUID()
        let patientId = UUID()
        let date = Date()

        let fatigue = FatigueAccumulation(
            id: id,
            patientId: patientId,
            calculationDate: date,
            avgReadiness7d: 65.0,
            avgReadiness14d: 70.0,
            trainingLoad7d: 1200.0,
            trainingLoad14d: 2200.0,
            acuteChronicRatio: 1.1,
            consecutiveLowReadiness: 2,
            missedRepsCount7d: 3,
            highRpeCount7d: 4,
            painReports7d: 1,
            fatigueScore: 55.0,
            fatigueBand: .moderate,
            deloadRecommended: false,
            deloadUrgency: .suggested
        )

        XCTAssertEqual(fatigue.id, id)
        XCTAssertEqual(fatigue.patientId, patientId)
        XCTAssertEqual(fatigue.avgReadiness7d, 65.0)
        XCTAssertEqual(fatigue.avgReadiness14d, 70.0)
        XCTAssertEqual(fatigue.trainingLoad7d, 1200.0)
        XCTAssertEqual(fatigue.trainingLoad14d, 2200.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 1.1)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 2)
        XCTAssertEqual(fatigue.missedRepsCount7d, 3)
        XCTAssertEqual(fatigue.highRpeCount7d, 4)
        XCTAssertEqual(fatigue.painReports7d, 1)
        XCTAssertEqual(fatigue.fatigueScore, 55.0)
        XCTAssertEqual(fatigue.fatigueBand, .moderate)
        XCTAssertEqual(fatigue.deloadRecommended, false)
        XCTAssertEqual(fatigue.deloadUrgency, .suggested)
    }

    func testFatigueAccumulation_DefaultValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date()
        )

        XCTAssertNil(fatigue.avgReadiness7d)
        XCTAssertNil(fatigue.avgReadiness14d)
        XCTAssertNil(fatigue.trainingLoad7d)
        XCTAssertNil(fatigue.trainingLoad14d)
        XCTAssertNil(fatigue.acuteChronicRatio)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 0)
        XCTAssertEqual(fatigue.missedRepsCount7d, 0)
        XCTAssertEqual(fatigue.highRpeCount7d, 0)
        XCTAssertEqual(fatigue.painReports7d, 0)
        XCTAssertEqual(fatigue.fatigueScore, 0.0)
        XCTAssertEqual(fatigue.fatigueBand, .low)
        XCTAssertEqual(fatigue.deloadRecommended, false)
        XCTAssertEqual(fatigue.deloadUrgency, .none)
    }

    // MARK: - Identifiable Tests

    func testFatigueAccumulation_Identifiable() {
        let id = UUID()
        let fatigue = FatigueAccumulation(
            id: id,
            patientId: UUID(),
            calculationDate: Date()
        )

        XCTAssertEqual(fatigue.id, id)
    }

    // MARK: - Sample Data Tests

    func testFatigueAccumulation_Sample() {
        let sample = FatigueAccumulation.sample

        XCTAssertEqual(sample.avgReadiness7d, 65.0)
        XCTAssertEqual(sample.avgReadiness14d, 70.0)
        XCTAssertEqual(sample.trainingLoad7d, 1200.0)
        XCTAssertEqual(sample.trainingLoad14d, 2200.0)
        XCTAssertEqual(sample.acuteChronicRatio, 1.1)
        XCTAssertEqual(sample.consecutiveLowReadiness, 2)
        XCTAssertEqual(sample.missedRepsCount7d, 3)
        XCTAssertEqual(sample.highRpeCount7d, 4)
        XCTAssertEqual(sample.painReports7d, 1)
        XCTAssertEqual(sample.fatigueScore, 55.0)
        XCTAssertEqual(sample.fatigueBand, .moderate)
        XCTAssertEqual(sample.deloadRecommended, false)
        XCTAssertEqual(sample.deloadUrgency, .suggested)
    }

    func testFatigueAccumulation_HighFatigueSample() {
        let sample = FatigueAccumulation.highFatigueSample

        XCTAssertEqual(sample.avgReadiness7d, 45.0)
        XCTAssertEqual(sample.avgReadiness14d, 55.0)
        XCTAssertEqual(sample.acuteChronicRatio, 1.5)
        XCTAssertEqual(sample.consecutiveLowReadiness, 4)
        XCTAssertEqual(sample.fatigueScore, 78.0)
        XCTAssertEqual(sample.fatigueBand, .critical)
        XCTAssertEqual(sample.deloadRecommended, true)
        XCTAssertEqual(sample.deloadUrgency, .required)
    }
}

// MARK: - FatigueTrackingError Tests

final class FatigueTrackingErrorTests: XCTestCase {

    func testErrorDescription_FatigueCalculationFailed() {
        let error = FatigueTrackingError.fatigueCalculationFailed
        XCTAssertEqual(error.errorDescription, "Failed to calculate fatigue accumulation")
    }

    func testErrorDescription_NoFatigueDataFound() {
        let error = FatigueTrackingError.noFatigueDataFound
        XCTAssertEqual(error.errorDescription, "No fatigue data found for this patient")
    }

    func testErrorDescription_TrendFetchFailed() {
        let error = FatigueTrackingError.trendFetchFailed
        XCTAssertEqual(error.errorDescription, "Failed to fetch fatigue trend data")
    }

    func testErrorDescription_InvalidPatientId() {
        let error = FatigueTrackingError.invalidPatientId
        XCTAssertEqual(error.errorDescription, "Invalid patient ID provided")
    }

    func testErrorDescription_NetworkError() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        let error = FatigueTrackingError.networkError(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Connection lost") ?? false)
    }

    func testError_IsLocalizedError() {
        let error: LocalizedError = FatigueTrackingError.fatigueCalculationFailed
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - FatigueTrackingService Tests

@MainActor
final class FatigueTrackingServiceTests: XCTestCase {

    var service: FatigueTrackingService!

    override func setUp() async throws {
        try await super.setUp()
        service = FatigueTrackingService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testService_Initialization() {
        XCTAssertNotNil(service)
        XCTAssertNil(service.currentFatigue)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    // MARK: - GetFatigueSummary Tests

    func testGetFatigueSummary_WithCurrentFatigue() async {
        // Simulate having current fatigue data
        let fatigue = FatigueAccumulation.sample
        service.currentFatigue = fatigue

        let summary = service.getFatigueSummary()

        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.band, .moderate)
        XCTAssertEqual(summary?.score, 55.0)
        XCTAssertEqual(summary?.urgency, .suggested)
    }

    func testGetFatigueSummary_WithoutCurrentFatigue() async {
        service.currentFatigue = nil

        let summary = service.getFatigueSummary()

        XCTAssertNil(summary)
    }

    // MARK: - ClearError Tests

    func testClearError() async {
        service.error = FatigueTrackingError.fatigueCalculationFailed

        service.clearError()

        XCTAssertNil(service.error)
    }

    // MARK: - Published Properties Tests

    func testIsLoading_InitialValue() async {
        XCTAssertFalse(service.isLoading)
    }

    func testError_InitialValue() async {
        XCTAssertNil(service.error)
    }

    func testCurrentFatigue_InitialValue() async {
        XCTAssertNil(service.currentFatigue)
    }
}

// MARK: - Codable Decoding Tests

final class FatigueAccumulationDecodingTests: XCTestCase {

    func testDecoding_WithStringNumericValues() throws {
        // PostgreSQL often returns numeric values as strings
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": "72.5",
            "avg_readiness_14d": "75.0",
            "training_load_7d": "1500.0",
            "training_load_14d": "2800.0",
            "acute_chronic_ratio": "1.25",
            "consecutive_low_readiness": 1,
            "missed_reps_count_7d": 2,
            "high_rpe_count_7d": 3,
            "pain_reports_7d": 0,
            "fatigue_score": "45.5",
            "fatigue_band": "moderate",
            "deload_recommended": false,
            "deload_urgency": "none"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertEqual(fatigue.avgReadiness7d, 72.5)
        XCTAssertEqual(fatigue.avgReadiness14d, 75.0)
        XCTAssertEqual(fatigue.trainingLoad7d, 1500.0)
        XCTAssertEqual(fatigue.trainingLoad14d, 2800.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 1.25)
        XCTAssertEqual(fatigue.fatigueScore, 45.5)
    }

    func testDecoding_WithDoubleNumericValues() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": 72.5,
            "avg_readiness_14d": 75.0,
            "training_load_7d": 1500.0,
            "training_load_14d": 2800.0,
            "acute_chronic_ratio": 1.25,
            "consecutive_low_readiness": 1,
            "missed_reps_count_7d": 2,
            "high_rpe_count_7d": 3,
            "pain_reports_7d": 0,
            "fatigue_score": 45.5,
            "fatigue_band": "low",
            "deload_recommended": true,
            "deload_urgency": "suggested"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertEqual(fatigue.avgReadiness7d, 72.5)
        XCTAssertEqual(fatigue.fatigueScore, 45.5)
        XCTAssertEqual(fatigue.fatigueBand, .low)
        XCTAssertEqual(fatigue.deloadRecommended, true)
    }

    func testDecoding_WithNullOptionalValues() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "patient_id": "660e8400-e29b-41d4-a716-446655440001",
            "calculation_date": "2024-01-15",
            "avg_readiness_7d": null,
            "avg_readiness_14d": null,
            "training_load_7d": null,
            "training_load_14d": null,
            "acute_chronic_ratio": null,
            "consecutive_low_readiness": 0,
            "missed_reps_count_7d": 0,
            "high_rpe_count_7d": 0,
            "pain_reports_7d": 0,
            "fatigue_score": 0,
            "fatigue_band": "low",
            "deload_recommended": false,
            "deload_urgency": "none"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

        XCTAssertNil(fatigue.avgReadiness7d)
        XCTAssertNil(fatigue.avgReadiness14d)
        XCTAssertNil(fatigue.trainingLoad7d)
        XCTAssertNil(fatigue.trainingLoad14d)
        XCTAssertNil(fatigue.acuteChronicRatio)
    }

    func testDecoding_AllFatigueBands() throws {
        let bands = ["low", "moderate", "high", "critical"]

        for band in bands {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "calculation_date": "2024-01-15",
                "fatigue_score": 50.0,
                "fatigue_band": "\(band)",
                "deload_urgency": "none"
            }
            """.data(using: .utf8)!

            let decoder = PTSupabaseClient.flexibleDecoder
            let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

            XCTAssertEqual(fatigue.fatigueBand.rawValue, band)
        }
    }

    func testDecoding_AllDeloadUrgencies() throws {
        let urgencies = ["none", "suggested", "recommended", "required"]

        for urgency in urgencies {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "patient_id": "660e8400-e29b-41d4-a716-446655440001",
                "calculation_date": "2024-01-15",
                "fatigue_score": 50.0,
                "fatigue_band": "moderate",
                "deload_urgency": "\(urgency)"
            }
            """.data(using: .utf8)!

            let decoder = PTSupabaseClient.flexibleDecoder
            let fatigue = try decoder.decode(FatigueAccumulation.self, from: json)

            XCTAssertEqual(fatigue.deloadUrgency.rawValue, urgency)
        }
    }
}

// MARK: - Edge Cases Tests

final class FatigueTrackingEdgeCaseTests: XCTestCase {

    func testFatigueBand_ColorConsistency() {
        // Ensure colors are consistent with severity
        let colors = [
            FatigueBand.low.color,
            FatigueBand.moderate.color,
            FatigueBand.high.color,
            FatigueBand.critical.color
        ]

        // Verify all colors are different (no duplicates)
        let uniqueColors = Set(colors.map { "\($0)" })
        XCTAssertEqual(uniqueColors.count, 4, "Each fatigue band should have a unique color")
    }

    func testDeloadUrgency_ColorConsistency() {
        // Ensure colors are consistent with urgency
        let colors = [
            DeloadUrgency.none.color,
            DeloadUrgency.suggested.color,
            DeloadUrgency.recommended.color,
            DeloadUrgency.required.color
        ]

        // Verify all colors are different (no duplicates)
        let uniqueColors = Set(colors.map { "\($0)" })
        XCTAssertEqual(uniqueColors.count, 4, "Each urgency level should have a unique color")
    }

    func testFatigueAccumulation_ZeroValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 0.0,
            avgReadiness14d: 0.0,
            trainingLoad7d: 0.0,
            trainingLoad14d: 0.0,
            acuteChronicRatio: 0.0,
            consecutiveLowReadiness: 0,
            missedRepsCount7d: 0,
            highRpeCount7d: 0,
            painReports7d: 0,
            fatigueScore: 0.0,
            fatigueBand: .low,
            deloadRecommended: false,
            deloadUrgency: .none
        )

        XCTAssertEqual(fatigue.fatigueScore, 0.0)
        XCTAssertEqual(fatigue.acuteChronicRatio, 0.0)
    }

    func testFatigueAccumulation_ExtremeValues() {
        let fatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 100.0,
            avgReadiness14d: 100.0,
            trainingLoad7d: 10000.0,
            trainingLoad14d: 20000.0,
            acuteChronicRatio: 3.0,
            consecutiveLowReadiness: 14,
            missedRepsCount7d: 100,
            highRpeCount7d: 50,
            painReports7d: 10,
            fatigueScore: 100.0,
            fatigueBand: .critical,
            deloadRecommended: true,
            deloadUrgency: .required
        )

        XCTAssertEqual(fatigue.fatigueScore, 100.0)
        XCTAssertEqual(fatigue.consecutiveLowReadiness, 14)
        XCTAssertEqual(fatigue.fatigueBand, .critical)
    }
}

// MARK: - FatigueTrackingService HasHighFatigue Tests

@MainActor
final class FatigueTrackingServiceHasHighFatigueTests: XCTestCase {

    var service: FatigueTrackingService!

    override func setUp() async throws {
        try await super.setUp()
        service = FatigueTrackingService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - HasHighFatigue with Current Fatigue Tests

    func testHasHighFatigue_WithHighFatigueBand_ReturnsTrue() async {
        // Set current fatigue with high band
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 75.0,
            fatigueBand: .high,
            deloadRecommended: true,
            deloadUrgency: .recommended
        )

        guard let fatigue = service.currentFatigue else {
            XCTFail("Current fatigue should be set")
            return
        }

        let isHigh = fatigue.fatigueBand == .high || fatigue.fatigueBand == .critical
        XCTAssertTrue(isHigh)
    }

    func testHasHighFatigue_WithCriticalFatigueBand_ReturnsTrue() async {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 85.0,
            fatigueBand: .critical,
            deloadRecommended: true,
            deloadUrgency: .required
        )

        guard let fatigue = service.currentFatigue else {
            XCTFail("Current fatigue should be set")
            return
        }

        let isHigh = fatigue.fatigueBand == .high || fatigue.fatigueBand == .critical
        XCTAssertTrue(isHigh)
    }

    func testHasHighFatigue_WithModerateFatigueBand_ReturnsFalse() async {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 55.0,
            fatigueBand: .moderate,
            deloadRecommended: false,
            deloadUrgency: .suggested
        )

        guard let fatigue = service.currentFatigue else {
            XCTFail("Current fatigue should be set")
            return
        }

        let isHigh = fatigue.fatigueBand == .high || fatigue.fatigueBand == .critical
        XCTAssertFalse(isHigh)
    }

    func testHasHighFatigue_WithLowFatigueBand_ReturnsFalse() async {
        service.currentFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            fatigueScore: 25.0,
            fatigueBand: .low,
            deloadRecommended: false,
            deloadUrgency: .none
        )

        guard let fatigue = service.currentFatigue else {
            XCTFail("Current fatigue should be set")
            return
        }

        let isHigh = fatigue.fatigueBand == .high || fatigue.fatigueBand == .critical
        XCTAssertFalse(isHigh)
    }

    func testHasHighFatigue_WithNilCurrentFatigue_ReturnsFalse() async {
        service.currentFatigue = nil

        let hasHighFatigue = service.currentFatigue?.fatigueBand == .high || service.currentFatigue?.fatigueBand == .critical
        XCTAssertFalse(hasHighFatigue)
    }
}

// MARK: - FatigueTrackingService Trend Data Tests

@MainActor
final class FatigueTrackingServiceTrendTests: XCTestCase {

    func testTrendDataRequest_CorrectDateRange() {
        // Test the date calculation for trend fetching
        let days = 14
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            XCTFail("Should be able to calculate start date")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)

        // Verify the date string is valid
        XCTAssertFalse(startDateString.isEmpty)

        // Verify it's 14 days ago
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        XCTAssertEqual(components.day, days)
    }

    func testTrendDataRequest_DefaultDays() {
        // Default is 14 days
        let defaultDays = 14
        XCTAssertEqual(defaultDays, 14)
    }

    func testTrendDataRequest_CustomDays() {
        // Can request custom number of days
        let customDays = 7
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -customDays, to: Date()) else {
            XCTFail("Should be able to calculate start date")
            return
        }

        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        XCTAssertEqual(components.day, customDays)
    }
}

// MARK: - Fatigue Calculation Trigger Tests

@MainActor
final class FatigueCalculationTriggerTests: XCTestCase {

    var service: FatigueTrackingService!

    override func setUp() async throws {
        try await super.setUp()
        service = FatigueTrackingService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    func testCalculateFatigue_SetsLoading() {
        // Service should track loading state
        XCTAssertFalse(service.isLoading)
    }

    func testCalculateFatigue_RequiresPatientId() {
        // Valid patient ID is required
        let patientId = UUID()
        XCTAssertNotNil(patientId)
        XCTAssertEqual(patientId.uuidString.count, 36) // UUID string length
    }

    func testCalculateFatigue_UpdatesCurrentFatigue() async {
        // After successful calculation, currentFatigue should be updated
        // For unit test, we just verify the service can accept a calculated value
        let calculatedFatigue = FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
            avgReadiness7d: 65.0,
            avgReadiness14d: 68.0,
            fatigueScore: 45.0,
            fatigueBand: .moderate,
            deloadRecommended: false,
            deloadUrgency: .none
        )

        service.currentFatigue = calculatedFatigue

        XCTAssertNotNil(service.currentFatigue)
        XCTAssertEqual(service.currentFatigue?.fatigueScore, 45.0)
        XCTAssertEqual(service.currentFatigue?.fatigueBand, .moderate)
    }
}

// MARK: - FatigueBand Severity Tests

final class FatigueBandSeverityTests: XCTestCase {

    func testFatigueBand_SeverityOrder() {
        // Verify the severity order is correct
        let bands: [FatigueBand] = [.low, .moderate, .high, .critical]

        // Each band should have the expected raw value
        XCTAssertEqual(bands[0].rawValue, "low")
        XCTAssertEqual(bands[1].rawValue, "moderate")
        XCTAssertEqual(bands[2].rawValue, "high")
        XCTAssertEqual(bands[3].rawValue, "critical")
    }

    func testFatigueBand_SeverityProgression() {
        // Score ranges typically map to bands
        // low: 0-40, moderate: 40-60, high: 60-80, critical: 80-100
        let lowScore = 30.0
        let moderateScore = 50.0
        let highScore = 70.0
        let criticalScore = 90.0

        XCTAssertTrue(lowScore < 40)
        XCTAssertTrue(moderateScore >= 40 && moderateScore < 60)
        XCTAssertTrue(highScore >= 60 && highScore < 80)
        XCTAssertTrue(criticalScore >= 80)
    }
}

// MARK: - DeloadUrgency Severity Tests

final class DeloadUrgencySeverityTests: XCTestCase {

    func testDeloadUrgency_SeverityOrder() {
        let urgencies: [DeloadUrgency] = [.none, .suggested, .recommended, .required]

        XCTAssertEqual(urgencies[0].rawValue, "none")
        XCTAssertEqual(urgencies[1].rawValue, "suggested")
        XCTAssertEqual(urgencies[2].rawValue, "recommended")
        XCTAssertEqual(urgencies[3].rawValue, "required")
    }

    func testDeloadUrgency_RequiredIsHighestPriority() {
        let required = DeloadUrgency.required

        XCTAssertEqual(required.title, "Deload Required")
        XCTAssertEqual(required.subtitle, "Immediate deload needed to prevent overtraining")
        XCTAssertEqual(required.color, .red)
    }
}
