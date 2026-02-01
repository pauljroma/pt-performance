//
//  ProgressiveOverloadAIServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProgressiveOverloadAIService
//  Tests model Codable encoding/decoding, computed properties, and business logic
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - ProgressionType Tests

final class ProgressionTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testProgressionType_RawValues() {
        XCTAssertEqual(ProgressionType.increase.rawValue, "increase")
        XCTAssertEqual(ProgressionType.hold.rawValue, "hold")
        XCTAssertEqual(ProgressionType.decrease.rawValue, "decrease")
        XCTAssertEqual(ProgressionType.deload.rawValue, "deload")
    }

    func testProgressionType_InitFromRawValue() {
        XCTAssertEqual(ProgressionType(rawValue: "increase"), .increase)
        XCTAssertEqual(ProgressionType(rawValue: "hold"), .hold)
        XCTAssertEqual(ProgressionType(rawValue: "decrease"), .decrease)
        XCTAssertEqual(ProgressionType(rawValue: "deload"), .deload)
        XCTAssertNil(ProgressionType(rawValue: "invalid"))
    }

    // MARK: - Color Tests

    func testProgressionType_Colors() {
        XCTAssertEqual(ProgressionType.increase.color, .green)
        XCTAssertEqual(ProgressionType.hold.color, .blue)
        XCTAssertEqual(ProgressionType.decrease.color, .orange)
        XCTAssertEqual(ProgressionType.deload.color, .red)
    }

    // MARK: - Icon Tests

    func testProgressionType_Icons() {
        XCTAssertEqual(ProgressionType.increase.icon, "arrow.up.circle.fill")
        XCTAssertEqual(ProgressionType.hold.icon, "equal.circle.fill")
        XCTAssertEqual(ProgressionType.decrease.icon, "arrow.down.circle.fill")
        XCTAssertEqual(ProgressionType.deload.icon, "bed.double.circle.fill")
    }

    // MARK: - Display Text Tests

    func testProgressionType_DisplayText() {
        XCTAssertEqual(ProgressionType.increase.displayText, "Increase Load")
        XCTAssertEqual(ProgressionType.hold.displayText, "Maintain Load")
        XCTAssertEqual(ProgressionType.decrease.displayText, "Reduce Load")
        XCTAssertEqual(ProgressionType.deload.displayText, "Deload Week")
    }

    // MARK: - Codable Tests

    func testProgressionType_Encoding() throws {
        let type = ProgressionType.increase
        let encoder = JSONEncoder()
        let data = try encoder.encode(type)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"increase\"")
    }

    func testProgressionType_Decoding() throws {
        let json = "\"deload\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let type = try decoder.decode(ProgressionType.self, from: json)

        XCTAssertEqual(type, .deload)
    }
}

// MARK: - TrendType Tests

final class TrendTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testTrendType_RawValues() {
        XCTAssertEqual(TrendType.improving.rawValue, "improving")
        XCTAssertEqual(TrendType.plateaued.rawValue, "plateaued")
        XCTAssertEqual(TrendType.declining.rawValue, "declining")
    }

    func testTrendType_InitFromRawValue() {
        XCTAssertEqual(TrendType(rawValue: "improving"), .improving)
        XCTAssertEqual(TrendType(rawValue: "plateaued"), .plateaued)
        XCTAssertEqual(TrendType(rawValue: "declining"), .declining)
        XCTAssertNil(TrendType(rawValue: "unknown"))
    }

    // MARK: - Color Tests

    func testTrendType_Colors() {
        XCTAssertEqual(TrendType.improving.color, .green)
        XCTAssertEqual(TrendType.plateaued.color, .orange)
        XCTAssertEqual(TrendType.declining.color, .red)
    }

    // MARK: - Icon Tests

    func testTrendType_Icons() {
        XCTAssertEqual(TrendType.improving.icon, "arrow.up.right")
        XCTAssertEqual(TrendType.plateaued.icon, "arrow.right")
        XCTAssertEqual(TrendType.declining.icon, "arrow.down.right")
    }

    // MARK: - Display Text Tests

    func testTrendType_DisplayText() {
        XCTAssertEqual(TrendType.improving.displayText, "Improving")
        XCTAssertEqual(TrendType.plateaued.displayText, "Plateaued")
        XCTAssertEqual(TrendType.declining.displayText, "Declining")
    }
}

// MARK: - ProgressionSuggestion Tests

final class ProgressionSuggestionTests: XCTestCase {

    // MARK: - Codable Tests

    func testProgressionSuggestion_Decoding() throws {
        let json = """
        {
            "next_load": 140.0,
            "next_reps": 8,
            "confidence": 85,
            "reasoning": "Consistent performance warrants progression",
            "progression_type": "increase"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(ProgressionSuggestion.self, from: json)

        XCTAssertEqual(suggestion.nextLoad, 140.0)
        XCTAssertEqual(suggestion.nextReps, 8)
        XCTAssertEqual(suggestion.confidence, 85)
        XCTAssertEqual(suggestion.reasoning, "Consistent performance warrants progression")
        XCTAssertEqual(suggestion.progressionType, .increase)
    }

    func testProgressionSuggestion_Encoding() throws {
        let suggestion = ProgressionSuggestion(
            nextLoad: 135.0,
            nextReps: 10,
            confidence: 78,
            reasoning: "Hold at current weight",
            progressionType: .hold
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(suggestion)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"next_load\":135"))
        XCTAssertTrue(jsonString.contains("\"next_reps\":10"))
        XCTAssertTrue(jsonString.contains("\"confidence\":78"))
        XCTAssertTrue(jsonString.contains("\"progression_type\":\"hold\""))
    }

    func testProgressionSuggestion_RoundTrip() throws {
        let original = ProgressionSuggestion(
            nextLoad: 150.0,
            nextReps: 6,
            confidence: 92,
            reasoning: "Strong performance across all sets",
            progressionType: .increase
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProgressionSuggestion.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Confidence Level Tests

    func testProgressionSuggestion_ConfidenceLevel_High() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        XCTAssertEqual(suggestion.confidenceLevel, "High")
    }

    func testProgressionSuggestion_ConfidenceLevel_Moderate() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 70,
            reasoning: "Test",
            progressionType: .hold
        )

        XCTAssertEqual(suggestion.confidenceLevel, "Moderate")
    }

    func testProgressionSuggestion_ConfidenceLevel_Low() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 45,
            reasoning: "Test",
            progressionType: .decrease
        )

        XCTAssertEqual(suggestion.confidenceLevel, "Low")
    }

    func testProgressionSuggestion_ConfidenceLevel_BoundaryAt80() {
        let high = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 80,
            reasoning: "Test",
            progressionType: .increase
        )
        XCTAssertEqual(high.confidenceLevel, "High")

        let moderate = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 79,
            reasoning: "Test",
            progressionType: .increase
        )
        XCTAssertEqual(moderate.confidenceLevel, "Moderate")
    }

    func testProgressionSuggestion_ConfidenceLevel_BoundaryAt60() {
        let moderate = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 60,
            reasoning: "Test",
            progressionType: .hold
        )
        XCTAssertEqual(moderate.confidenceLevel, "Moderate")

        let low = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 59,
            reasoning: "Test",
            progressionType: .decrease
        )
        XCTAssertEqual(low.confidenceLevel, "Low")
    }

    // MARK: - Confidence Color Tests

    func testProgressionSuggestion_ConfidenceColor_High() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 90,
            reasoning: "Test",
            progressionType: .increase
        )

        XCTAssertEqual(suggestion.confidenceColor, .green)
    }

    func testProgressionSuggestion_ConfidenceColor_Moderate() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 65,
            reasoning: "Test",
            progressionType: .hold
        )

        XCTAssertEqual(suggestion.confidenceColor, .orange)
    }

    func testProgressionSuggestion_ConfidenceColor_Low() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 50,
            reasoning: "Test",
            progressionType: .decrease
        )

        XCTAssertEqual(suggestion.confidenceColor, .gray)
    }

    // MARK: - Load Change Description Tests

    func testProgressionSuggestion_LoadChangeDescription_Increase() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        let description = suggestion.loadChangeDescription(from: 135.0)
        XCTAssertEqual(description, "+5.0 lbs")
    }

    func testProgressionSuggestion_LoadChangeDescription_Decrease() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 125.0,
            nextReps: 8,
            confidence: 75,
            reasoning: "Test",
            progressionType: .decrease
        )

        let description = suggestion.loadChangeDescription(from: 135.0)
        XCTAssertEqual(description, "-10.0 lbs")
    }

    func testProgressionSuggestion_LoadChangeDescription_NoChange() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 135.0,
            nextReps: 8,
            confidence: 70,
            reasoning: "Test",
            progressionType: .hold
        )

        let description = suggestion.loadChangeDescription(from: 135.0)
        XCTAssertEqual(description, "No change")
    }

    func testProgressionSuggestion_LoadChangeDescription_SmallChange() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 135.05,
            nextReps: 8,
            confidence: 70,
            reasoning: "Test",
            progressionType: .hold
        )

        let description = suggestion.loadChangeDescription(from: 135.0)
        XCTAssertEqual(description, "No change", "Changes < 0.1 should show No change")
    }

    // MARK: - Equatable Tests

    func testProgressionSuggestion_Equatable_Equal() {
        let suggestion1 = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        let suggestion2 = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        XCTAssertEqual(suggestion1, suggestion2)
    }

    func testProgressionSuggestion_Equatable_NotEqual() {
        let suggestion1 = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        let suggestion2 = ProgressionSuggestion(
            nextLoad: 145.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )

        XCTAssertNotEqual(suggestion1, suggestion2)
    }
}

// MARK: - ProgressionAnalysis Tests

final class ProgressionAnalysisTests: XCTestCase {

    // MARK: - Codable Tests

    func testProgressionAnalysis_Decoding() throws {
        let json = """
        {
            "trend": "improving",
            "estimated_1rm": 175.5,
            "sessions_at_weight": 4,
            "fatigue_impact": "low - good for progression"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(ProgressionAnalysis.self, from: json)

        XCTAssertEqual(analysis.trend, "improving")
        XCTAssertEqual(analysis.estimated1RM, 175.5)
        XCTAssertEqual(analysis.sessionsAtWeight, 4)
        XCTAssertEqual(analysis.fatigueImpact, "low - good for progression")
    }

    func testProgressionAnalysis_Encoding() throws {
        let analysis = ProgressionAnalysis(
            trend: "plateaued",
            estimated1RM: 165.0,
            sessionsAtWeight: 6,
            fatigueImpact: "moderate - consider progression carefully"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(analysis)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"trend\":\"plateaued\""))
        XCTAssertTrue(jsonString.contains("\"estimated_1rm\":165"))
        XCTAssertTrue(jsonString.contains("\"sessions_at_weight\":6"))
    }

    func testProgressionAnalysis_RoundTrip() throws {
        let original = ProgressionAnalysis(
            trend: "declining",
            estimated1RM: 155.0,
            sessionsAtWeight: 2,
            fatigueImpact: "high - consider deload"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProgressionAnalysis.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Computed Properties Tests

    func testProgressionAnalysis_TrendType_Improving() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 175.0,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )

        XCTAssertEqual(analysis.trendType, .improving)
    }

    func testProgressionAnalysis_TrendType_Plateaued() {
        let analysis = ProgressionAnalysis(
            trend: "plateaued",
            estimated1RM: 165.0,
            sessionsAtWeight: 5,
            fatigueImpact: "moderate"
        )

        XCTAssertEqual(analysis.trendType, .plateaued)
    }

    func testProgressionAnalysis_TrendType_Declining() {
        let analysis = ProgressionAnalysis(
            trend: "declining",
            estimated1RM: 155.0,
            sessionsAtWeight: 2,
            fatigueImpact: "high"
        )

        XCTAssertEqual(analysis.trendType, .declining)
    }

    func testProgressionAnalysis_TrendType_Unknown() {
        let analysis = ProgressionAnalysis(
            trend: "unknown_trend",
            estimated1RM: 160.0,
            sessionsAtWeight: 3,
            fatigueImpact: "moderate"
        )

        // Should default to improving for unknown trends
        XCTAssertEqual(analysis.trendType, .improving)
    }

    func testProgressionAnalysis_Estimated1RMFormatted() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 172.5,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "172.5 lbs")
    }

    func testProgressionAnalysis_Estimated1RMFormatted_WholeNumber() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 180.0,
            sessionsAtWeight: 4,
            fatigueImpact: "low"
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "180.0 lbs")
    }

    // MARK: - Equatable Tests

    func testProgressionAnalysis_Equatable() {
        let analysis1 = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 175.0,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )

        let analysis2 = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 175.0,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )

        XCTAssertEqual(analysis1, analysis2)
    }
}

// MARK: - ProgressionError Tests

final class ProgressionErrorTests: XCTestCase {

    func testErrorDescription_ServerError() {
        let error = ProgressionError.serverError("Internal server error")
        XCTAssertEqual(error.errorDescription, "Internal server error")
    }

    func testErrorDescription_InvalidResponse() {
        let error = ProgressionError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Received an invalid response from the server.")
    }

    func testErrorDescription_NoData() {
        let error = ProgressionError.noData
        XCTAssertEqual(error.errorDescription, "No progression data available.")
    }

    func testError_IsLocalizedError() {
        let error: LocalizedError = ProgressionError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - ProgressiveOverloadAIService Tests

@MainActor
final class ProgressiveOverloadAIServiceTests: XCTestCase {

    var service: ProgressiveOverloadAIService!

    override func setUp() async throws {
        try await super.setUp()
        service = ProgressiveOverloadAIService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testService_Initialization() {
        XCTAssertNotNil(service)
        XCTAssertNil(service.suggestion)
        XCTAssertNil(service.analysis)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    // MARK: - ClearSuggestion Tests

    func testClearSuggestion() async {
        // Simulate having data
        service.suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase
        )
        service.analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 175.0,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )
        service.error = "Some error"

        service.clearSuggestion()

        XCTAssertNil(service.suggestion)
        XCTAssertNil(service.analysis)
        XCTAssertNil(service.error)
        XCTAssertFalse(service.isLoading)
    }

    // MARK: - Published Properties Tests

    func testIsLoading_InitialValue() async {
        XCTAssertFalse(service.isLoading)
    }

    func testError_InitialValue() async {
        XCTAssertNil(service.error)
    }

    func testSuggestion_InitialValue() async {
        XCTAssertNil(service.suggestion)
    }

    func testAnalysis_InitialValue() async {
        XCTAssertNil(service.analysis)
    }
}

// MARK: - Preview Support Tests

#if DEBUG
@MainActor
final class ProgressiveOverloadPreviewTests: XCTestCase {

    func testPreview_HasSuggestion() {
        let service = ProgressiveOverloadAIService.preview

        XCTAssertNotNil(service.suggestion)
        XCTAssertEqual(service.suggestion?.nextLoad, 137.5)
        XCTAssertEqual(service.suggestion?.nextReps, 8)
        XCTAssertEqual(service.suggestion?.confidence, 82)
        XCTAssertEqual(service.suggestion?.progressionType, .increase)
    }

    func testPreview_HasAnalysis() {
        let service = ProgressiveOverloadAIService.preview

        XCTAssertNotNil(service.analysis)
        XCTAssertEqual(service.analysis?.trend, "improving")
        XCTAssertEqual(service.analysis?.estimated1RM, 172.5)
        XCTAssertEqual(service.analysis?.sessionsAtWeight, 3)
    }

    func testPreviewDeload_HasDeloadSuggestion() {
        let service = ProgressiveOverloadAIService.previewDeload

        XCTAssertNotNil(service.suggestion)
        XCTAssertEqual(service.suggestion?.progressionType, .deload)
        XCTAssertEqual(service.suggestion?.nextLoad, 115)
        XCTAssertEqual(service.suggestion?.confidence, 88)
    }

    func testPreviewDeload_HasDecliningAnalysis() {
        let service = ProgressiveOverloadAIService.previewDeload

        XCTAssertNotNil(service.analysis)
        XCTAssertEqual(service.analysis?.trend, "declining")
        XCTAssertEqual(service.analysis?.trendType, .declining)
    }
}
#endif

// MARK: - Edge Cases Tests

final class ProgressiveOverloadEdgeCaseTests: XCTestCase {

    func testProgressionType_ColorUniqueness() {
        let colors = [
            ProgressionType.increase.color,
            ProgressionType.hold.color,
            ProgressionType.decrease.color,
            ProgressionType.deload.color
        ]

        let uniqueColors = Set(colors.map { "\($0)" })
        XCTAssertEqual(uniqueColors.count, 4, "Each progression type should have a unique color")
    }

    func testTrendType_ColorUniqueness() {
        let colors = [
            TrendType.improving.color,
            TrendType.plateaued.color,
            TrendType.declining.color
        ]

        let uniqueColors = Set(colors.map { "\($0)" })
        XCTAssertEqual(uniqueColors.count, 3, "Each trend type should have a unique color")
    }

    func testProgressionSuggestion_ZeroConfidence() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 135.0,
            nextReps: 8,
            confidence: 0,
            reasoning: "Insufficient data",
            progressionType: .hold
        )

        XCTAssertEqual(suggestion.confidenceLevel, "Low")
        XCTAssertEqual(suggestion.confidenceColor, .gray)
    }

    func testProgressionSuggestion_MaxConfidence() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 150.0,
            nextReps: 8,
            confidence: 100,
            reasoning: "Perfect form and progression",
            progressionType: .increase
        )

        XCTAssertEqual(suggestion.confidenceLevel, "High")
        XCTAssertEqual(suggestion.confidenceColor, .green)
    }

    func testProgressionSuggestion_NegativeLoadChange() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 100.0,
            nextReps: 6,
            confidence: 75,
            reasoning: "Reduce load for recovery",
            progressionType: .decrease
        )

        let description = suggestion.loadChangeDescription(from: 150.0)
        XCTAssertEqual(description, "-50.0 lbs")
    }

    func testProgressionSuggestion_LargeLoadIncrease() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 200.0,
            nextReps: 5,
            confidence: 60,
            reasoning: "Significant jump",
            progressionType: .increase
        )

        let description = suggestion.loadChangeDescription(from: 135.0)
        XCTAssertEqual(description, "+65.0 lbs")
    }

    func testProgressionAnalysis_ZeroSessionsAtWeight() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 175.0,
            sessionsAtWeight: 0,
            fatigueImpact: "unknown - new weight"
        )

        XCTAssertEqual(analysis.sessionsAtWeight, 0)
    }

    func testProgressionAnalysis_VeryHighEstimated1RM() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 500.0,
            sessionsAtWeight: 10,
            fatigueImpact: "low"
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "500.0 lbs")
    }

    func testProgressionAnalysis_DecimalEstimated1RM() {
        let analysis = ProgressionAnalysis(
            trend: "improving",
            estimated1RM: 172.75,
            sessionsAtWeight: 3,
            fatigueImpact: "low"
        )

        // Should round to 1 decimal place
        XCTAssertEqual(analysis.estimated1RMFormatted, "172.8 lbs")
    }
}
