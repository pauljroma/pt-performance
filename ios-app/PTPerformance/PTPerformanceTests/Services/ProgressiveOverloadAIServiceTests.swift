//
//  ProgressiveOverloadAIServiceTests.swift
//  PTPerformanceTests
//
//  Unit tests for ProgressiveOverloadAIService
//  Tests model Codable encoding/decoding, computed properties, and business logic
//  Including ExercisePerformance, PerformanceTrend, ProgressionSuggestion, and service state
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

// MARK: - PerformanceTrend Tests

final class PerformanceTrendTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testPerformanceTrend_RawValues() {
        XCTAssertEqual(PerformanceTrend.improving.rawValue, "improving")
        XCTAssertEqual(PerformanceTrend.plateaued.rawValue, "plateaued")
        XCTAssertEqual(PerformanceTrend.declining.rawValue, "declining")
    }

    func testPerformanceTrend_InitFromRawValue() {
        XCTAssertEqual(PerformanceTrend(rawValue: "improving"), .improving)
        XCTAssertEqual(PerformanceTrend(rawValue: "plateaued"), .plateaued)
        XCTAssertEqual(PerformanceTrend(rawValue: "declining"), .declining)
        XCTAssertNil(PerformanceTrend(rawValue: "unknown"))
    }

    // MARK: - Color Tests

    func testPerformanceTrend_Colors() {
        XCTAssertEqual(PerformanceTrend.improving.color, .green)
        XCTAssertEqual(PerformanceTrend.plateaued.color, .orange)
        XCTAssertEqual(PerformanceTrend.declining.color, .red)
    }

    // MARK: - Icon Tests

    func testPerformanceTrend_Icons() {
        XCTAssertEqual(PerformanceTrend.improving.icon, "arrow.up.right")
        XCTAssertEqual(PerformanceTrend.plateaued.icon, "arrow.right")
        XCTAssertEqual(PerformanceTrend.declining.icon, "arrow.down.right")
    }

    // MARK: - Display Text Tests

    func testPerformanceTrend_DisplayText() {
        XCTAssertEqual(PerformanceTrend.improving.displayText, "Improving")
        XCTAssertEqual(PerformanceTrend.plateaued.displayText, "Plateaued")
        XCTAssertEqual(PerformanceTrend.declining.displayText, "Declining")
    }

    // MARK: - Codable Tests

    func testPerformanceTrend_Encoding() throws {
        let trend = PerformanceTrend.improving
        let encoder = JSONEncoder()
        let data = try encoder.encode(trend)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertEqual(jsonString, "\"improving\"")
    }

    func testPerformanceTrend_Decoding() throws {
        let json = "\"declining\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let trend = try decoder.decode(PerformanceTrend.self, from: json)

        XCTAssertEqual(trend, .declining)
    }

    // MARK: - Backward Compatibility Tests

    func testTrendType_IsAliasForPerformanceTrend() {
        // TrendType is a typealias for PerformanceTrend for backward compatibility
        let trend: TrendType = .improving
        XCTAssertEqual(trend, PerformanceTrend.improving)
    }
}

// MARK: - ExercisePerformance Tests

final class ExercisePerformanceTests: XCTestCase {

    // MARK: - Initialization Tests

    func testExercisePerformance_Initialization() {
        let date = Date()
        let entry = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 7],
            rpe: 7.5
        )

        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.load, 135.0)
        XCTAssertEqual(entry.reps, [8, 8, 7])
        XCTAssertEqual(entry.rpe, 7.5)
    }

    // MARK: - Computed Properties Tests

    func testExercisePerformance_AverageReps() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [8, 8, 7],
            rpe: 7.5
        )

        // Average of [8, 8, 7] = 23 / 3 = 7.67
        XCTAssertEqual(entry.averageReps, 7.67, accuracy: 0.01)
    }

    func testExercisePerformance_AverageReps_SingleSet() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [10],
            rpe: 7.0
        )

        XCTAssertEqual(entry.averageReps, 10.0)
    }

    func testExercisePerformance_AverageReps_EmptyReps() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [],
            rpe: 7.0
        )

        XCTAssertEqual(entry.averageReps, 0.0)
    }

    func testExercisePerformance_TotalVolume() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [8, 8, 7],
            rpe: 7.5
        )

        // Total reps = 8 + 8 + 7 = 23
        // Volume = 135 * 23 = 3105
        XCTAssertEqual(entry.totalVolume, 3105.0)
    }

    func testExercisePerformance_TotalVolume_SingleSet() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 100.0,
            reps: [10],
            rpe: 7.0
        )

        XCTAssertEqual(entry.totalVolume, 1000.0)
    }

    func testExercisePerformance_TotalVolume_EmptyReps() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [],
            rpe: 7.0
        )

        XCTAssertEqual(entry.totalVolume, 0.0)
    }

    func testExercisePerformance_SetCount() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [8, 8, 7, 6],
            rpe: 8.0
        )

        XCTAssertEqual(entry.setCount, 4)
    }

    func testExercisePerformance_SetCount_Empty() {
        let entry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [],
            rpe: 7.0
        )

        XCTAssertEqual(entry.setCount, 0)
    }

    // MARK: - Codable Tests

    func testExercisePerformance_Encoding() throws {
        let date = Date()
        let entry = ExercisePerformance(
            date: date,
            load: 145.0,
            reps: [6, 6, 5],
            rpe: 8.5
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"load\":145"))
        XCTAssertTrue(jsonString.contains("\"reps\":[6,6,5]"))
        XCTAssertTrue(jsonString.contains("\"rpe\":8.5"))
    }

    func testExercisePerformance_Decoding() throws {
        let json = """
        {
            "date": "2024-01-15T10:00:00Z",
            "load": 155.0,
            "reps": [5, 5, 4],
            "rpe": 9.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(ExercisePerformance.self, from: json)

        XCTAssertEqual(entry.load, 155.0)
        XCTAssertEqual(entry.reps, [5, 5, 4])
        XCTAssertEqual(entry.rpe, 9.0)
    }

    func testExercisePerformance_RoundTrip() throws {
        let original = ExercisePerformance(
            date: Date(),
            load: 165.0,
            reps: [8, 7, 7],
            rpe: 8.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExercisePerformance.self, from: data)

        XCTAssertEqual(decoded.load, original.load)
        XCTAssertEqual(decoded.reps, original.reps)
        XCTAssertEqual(decoded.rpe, original.rpe)
    }

    // MARK: - Equatable Tests

    func testExercisePerformance_Equatable_Equal() {
        let date = Date()
        let entry1 = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )

        let entry2 = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )

        XCTAssertEqual(entry1, entry2)
    }

    func testExercisePerformance_Equatable_NotEqual_DifferentLoad() {
        let date = Date()
        let entry1 = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )

        let entry2 = ExercisePerformance(
            date: date,
            load: 140.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )

        XCTAssertNotEqual(entry1, entry2)
    }

    func testExercisePerformance_Equatable_NotEqual_DifferentReps() {
        let date = Date()
        let entry1 = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )

        let entry2 = ExercisePerformance(
            date: date,
            load: 135.0,
            reps: [8, 8, 7],
            rpe: 7.0
        )

        XCTAssertNotEqual(entry1, entry2)
    }

    // MARK: - Sample Data Tests

    func testExercisePerformance_SampleEntries() {
        let samples = ExercisePerformance.sampleEntries

        XCTAssertEqual(samples.count, 3)

        // First entry should be most recent
        let firstEntry = samples[0]
        XCTAssertEqual(firstEntry.load, 135.0)
        XCTAssertEqual(firstEntry.reps, [8, 8, 7])
        XCTAssertEqual(firstEntry.rpe, 7.5)
    }

    // MARK: - Backward Compatibility Tests

    func testPerformanceEntry_IsAliasForExercisePerformance() {
        // PerformanceEntry is a typealias for ExercisePerformance
        let entry: PerformanceEntry = ExercisePerformance(
            date: Date(),
            load: 135.0,
            reps: [8, 8, 8],
            rpe: 7.0
        )
        XCTAssertEqual(entry.load, 135.0)
    }
}

// MARK: - PerformanceAnalysis Tests

final class PerformanceAnalysisTests: XCTestCase {

    // MARK: - Initialization Tests

    func testPerformanceAnalysis_Initialization() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "stable",
            fatigueImpact: "low - good for progression",
            recentSessions: 3
        )

        XCTAssertEqual(analysis.trend, .improving)
        XCTAssertEqual(analysis.estimated1RM, 175.0)
        XCTAssertEqual(analysis.velocityTrend, "stable")
        XCTAssertEqual(analysis.fatigueImpact, "low - good for progression")
        XCTAssertEqual(analysis.recentSessions, 3)
    }

    func testPerformanceAnalysis_Initialization_NilOptionals() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: nil,
            velocityTrend: nil,
            fatigueImpact: nil,
            recentSessions: 0
        )

        XCTAssertEqual(analysis.trend, .plateaued)
        XCTAssertNil(analysis.estimated1RM)
        XCTAssertNil(analysis.velocityTrend)
        XCTAssertNil(analysis.fatigueImpact)
        XCTAssertEqual(analysis.recentSessions, 0)
    }

    // MARK: - Computed Properties Tests

    func testPerformanceAnalysis_Estimated1RMFormatted() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 172.5,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "172.5 lbs")
    }

    func testPerformanceAnalysis_Estimated1RMFormatted_WholeNumber() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 180.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 4
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "180.0 lbs")
    }

    func testPerformanceAnalysis_Estimated1RMFormatted_Nil() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: nil,
            velocityTrend: nil,
            fatigueImpact: nil,
            recentSessions: 0
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "N/A")
    }

    // MARK: - VelocityTrendColor Tests

    func testPerformanceAnalysis_VelocityTrendColor_Increasing() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "increasing",
            fatigueImpact: "low",
            recentSessions: 3
        )

        XCTAssertEqual(analysis.velocityTrendColor, .green)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Improving() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "improving",
            fatigueImpact: "low",
            recentSessions: 3
        )

        XCTAssertEqual(analysis.velocityTrendColor, .green)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Stable() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: 165.0,
            velocityTrend: "stable",
            fatigueImpact: "moderate",
            recentSessions: 4
        )

        XCTAssertEqual(analysis.velocityTrendColor, .blue)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Maintaining() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: 165.0,
            velocityTrend: "maintaining",
            fatigueImpact: "moderate",
            recentSessions: 4
        )

        XCTAssertEqual(analysis.velocityTrendColor, .blue)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Decreasing() {
        let analysis = PerformanceAnalysis(
            trend: .declining,
            estimated1RM: 155.0,
            velocityTrend: "decreasing",
            fatigueImpact: "high",
            recentSessions: 5
        )

        XCTAssertEqual(analysis.velocityTrendColor, .orange)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Declining() {
        let analysis = PerformanceAnalysis(
            trend: .declining,
            estimated1RM: 155.0,
            velocityTrend: "declining",
            fatigueImpact: "high",
            recentSessions: 5
        )

        XCTAssertEqual(analysis.velocityTrendColor, .orange)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Unknown() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: 160.0,
            velocityTrend: "unknown",
            fatigueImpact: "moderate",
            recentSessions: 3
        )

        XCTAssertEqual(analysis.velocityTrendColor, .gray)
    }

    func testPerformanceAnalysis_VelocityTrendColor_Nil() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: 160.0,
            velocityTrend: nil,
            fatigueImpact: nil,
            recentSessions: 0
        )

        XCTAssertEqual(analysis.velocityTrendColor, .gray)
    }

    // MARK: - Codable Tests

    func testPerformanceAnalysis_Encoding() throws {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(analysis)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"trend\":\"improving\""))
        XCTAssertTrue(jsonString.contains("\"estimated_1rm\":175"))
        XCTAssertTrue(jsonString.contains("\"recent_sessions\":3"))
    }

    func testPerformanceAnalysis_Decoding() throws {
        let json = """
        {
            "trend": "plateaued",
            "estimated_1rm": 165.0,
            "velocity_trend": "stable",
            "fatigue_impact": "moderate",
            "recent_sessions": 4
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let analysis = try decoder.decode(PerformanceAnalysis.self, from: json)

        XCTAssertEqual(analysis.trend, .plateaued)
        XCTAssertEqual(analysis.estimated1RM, 165.0)
        XCTAssertEqual(analysis.velocityTrend, "stable")
        XCTAssertEqual(analysis.fatigueImpact, "moderate")
        XCTAssertEqual(analysis.recentSessions, 4)
    }

    func testPerformanceAnalysis_RoundTrip() throws {
        let original = PerformanceAnalysis(
            trend: .declining,
            estimated1RM: 155.0,
            velocityTrend: "decreasing",
            fatigueImpact: "high",
            recentSessions: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PerformanceAnalysis.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testPerformanceAnalysis_Equatable() {
        let analysis1 = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        let analysis2 = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        XCTAssertEqual(analysis1, analysis2)
    }

    // MARK: - Sample Data Tests

    func testPerformanceAnalysis_Sample() {
        let sample = PerformanceAnalysis.sample

        XCTAssertEqual(sample.trend, .improving)
        XCTAssertEqual(sample.estimated1RM, 172.5)
        XCTAssertEqual(sample.recentSessions, 3)
    }
}

// MARK: - ProgressionSuggestion Tests

final class ProgressionSuggestionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testProgressionSuggestion_ConvenienceInitializer() {
        let suggestion = ProgressionSuggestion(
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test reasoning",
            progressionType: .increase
        )

        XCTAssertEqual(suggestion.nextLoad, 140.0)
        XCTAssertEqual(suggestion.nextReps, 8)
        XCTAssertEqual(suggestion.confidence, 85)
        XCTAssertEqual(suggestion.reasoning, "Test reasoning")
        XCTAssertEqual(suggestion.progressionType, .increase)
        XCTAssertNotNil(suggestion.id)
        XCTAssertNotNil(suggestion.analysis)
    }

    func testProgressionSuggestion_FullInitializer() {
        let id = UUID()
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 175.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        let suggestion = ProgressionSuggestion(
            id: id,
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test reasoning",
            progressionType: .increase,
            analysis: analysis
        )

        XCTAssertEqual(suggestion.id, id)
        XCTAssertEqual(suggestion.nextLoad, 140.0)
        XCTAssertEqual(suggestion.nextReps, 8)
        XCTAssertEqual(suggestion.confidence, 85)
        XCTAssertEqual(suggestion.reasoning, "Test reasoning")
        XCTAssertEqual(suggestion.progressionType, .increase)
        XCTAssertEqual(suggestion.analysis, analysis)
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

    // MARK: - Percentage Change Tests

    func testProgressionSuggestion_PercentageChange_Increase() {
        let suggestion = createSuggestion(nextLoad: 140.0)

        let currentLoad = 135.0
        let percentChange = suggestion.percentageChange(from: currentLoad)

        // (140 - 135) / 135 * 100 = 3.7%
        XCTAssertEqual(percentChange, 3.70, accuracy: 0.01)
    }

    func testProgressionSuggestion_PercentageChange_Decrease() {
        let suggestion = createSuggestion(nextLoad: 120.0, progressionType: .decrease)

        let currentLoad = 135.0
        let percentChange = suggestion.percentageChange(from: currentLoad)

        // (120 - 135) / 135 * 100 = -11.11%
        XCTAssertEqual(percentChange, -11.11, accuracy: 0.01)
    }

    func testProgressionSuggestion_PercentageChange_NoChange() {
        let suggestion = createSuggestion(nextLoad: 135.0, progressionType: .hold)

        let currentLoad = 135.0
        let percentChange = suggestion.percentageChange(from: currentLoad)

        XCTAssertEqual(percentChange, 0.0, accuracy: 0.01)
    }

    func testProgressionSuggestion_PercentageChange_ZeroCurrentLoad() {
        let suggestion = createSuggestion(nextLoad: 135.0)

        let currentLoad = 0.0
        let percentChange = suggestion.percentageChange(from: currentLoad)

        XCTAssertEqual(percentChange, 0.0)
    }

    // MARK: - Codable Tests

    func testProgressionSuggestion_RoundTrip() throws {
        let original = createSuggestion(nextLoad: 140.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProgressionSuggestion.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.nextLoad, original.nextLoad)
        XCTAssertEqual(decoded.nextReps, original.nextReps)
        XCTAssertEqual(decoded.confidence, original.confidence)
        XCTAssertEqual(decoded.reasoning, original.reasoning)
        XCTAssertEqual(decoded.progressionType, original.progressionType)
    }

    // MARK: - Identifiable Tests

    func testProgressionSuggestion_HasUniqueId() {
        let suggestion1 = createSuggestion(nextLoad: 140.0)
        let suggestion2 = createSuggestion(nextLoad: 140.0)

        XCTAssertNotEqual(suggestion1.id, suggestion2.id)
    }

    func testProgressionSuggestion_SameIdEquals() {
        let id = UUID()
        let analysis = PerformanceAnalysis.sample

        let suggestion1 = ProgressionSuggestion(
            id: id,
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase,
            analysis: analysis
        )

        let suggestion2 = ProgressionSuggestion(
            id: id,
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase,
            analysis: analysis
        )

        XCTAssertEqual(suggestion1.id, suggestion2.id)
    }

    func testProgressionSuggestion_Sample_HasValidId() {
        let sample = ProgressionSuggestion.sample

        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.id.uuidString.count, 36)
    }

    // MARK: - Equatable Tests

    func testProgressionSuggestion_Equatable_Equal() {
        let id = UUID()
        let analysis = PerformanceAnalysis.sample

        let suggestion1 = ProgressionSuggestion(
            id: id,
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase,
            analysis: analysis
        )

        let suggestion2 = ProgressionSuggestion(
            id: id,
            nextLoad: 140.0,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: .increase,
            analysis: analysis
        )

        XCTAssertEqual(suggestion1, suggestion2)
    }

    func testProgressionSuggestion_Equatable_NotEqual() {
        let suggestion1 = createSuggestion(nextLoad: 140.0)
        let suggestion2 = createSuggestion(nextLoad: 145.0)

        XCTAssertNotEqual(suggestion1, suggestion2)
    }

    // MARK: - Helper Functions

    private func createSuggestion(
        nextLoad: Double,
        progressionType: ProgressionType = .increase
    ) -> ProgressionSuggestion {
        ProgressionSuggestion(
            id: UUID(),
            nextLoad: nextLoad,
            nextReps: 8,
            confidence: 85,
            reasoning: "Test",
            progressionType: progressionType,
            analysis: PerformanceAnalysis(
                trend: .improving,
                estimated1RM: 175.0,
                velocityTrend: "stable",
                fatigueImpact: "low",
                recentSessions: 3
            )
        )
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

    func testError_RecoverySuggestion_ServerError() {
        let error = ProgressionError.serverError("Test error")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("try again") ?? false)
    }

    func testError_RecoverySuggestion_InvalidResponse() {
        let error = ProgressionError.invalidResponse
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testError_RecoverySuggestion_NoData() {
        let error = ProgressionError.noData
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("workouts") ?? false)
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
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    // MARK: - ClearSuggestion Tests

    func testClearSuggestion() async {
        // Simulate having data
        service.suggestion = ProgressionSuggestion.sample
        service.error = "Some error"

        service.clearSuggestion()

        XCTAssertNil(service.suggestion)
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

    // MARK: - 1RM Calculation Tests

    func testCalculateEstimated1RM_BasicCalculation() {
        // Epley formula: weight * (1 + reps/30)
        let estimated1RM = service.calculateEstimated1RM(weight: 135, reps: 10, rpe: nil)

        // 135 * (1 + 10/30) = 135 * 1.333 = 180
        XCTAssertEqual(estimated1RM, 180.0, accuracy: 0.1)
    }

    func testCalculateEstimated1RM_WithRPEAdjustment() {
        // With RPE 8, there are 2 reps in reserve
        let estimated1RM = service.calculateEstimated1RM(weight: 135, reps: 10, rpe: 8.0)

        // Base: 135 * (1 + 10/30) = 180
        // RIR = 10 - 8 = 2, adjustment = 1 + (2 * 0.033) = 1.066
        // Final: 180 * 1.066 = 191.88
        XCTAssertEqual(estimated1RM, 191.88, accuracy: 0.5)
    }

    func testCalculateEstimated1RM_ZeroReps() {
        let estimated1RM = service.calculateEstimated1RM(weight: 135, reps: 0, rpe: nil)

        XCTAssertEqual(estimated1RM, 135.0)
    }

    func testCalculateEstimated1RM_RPE10NoAdjustment() {
        // RPE 10 should not apply adjustment
        let estimated1RM = service.calculateEstimated1RM(weight: 135, reps: 10, rpe: 10.0)

        // 135 * (1 + 10/30) = 180
        XCTAssertEqual(estimated1RM, 180.0, accuracy: 0.1)
    }

    // MARK: - Local Suggestion Generation Tests

    func testGenerateLocalSuggestion_NoData() {
        let suggestion = service.generateLocalSuggestion(recentPerformance: [])

        XCTAssertEqual(suggestion.nextLoad, 0)
        XCTAssertEqual(suggestion.progressionType, .hold)
        XCTAssertEqual(suggestion.confidence, 0)
    }

    func testGenerateLocalSuggestion_LowRPE_SuggestsIncrease() {
        let performance = [
            ExercisePerformance(date: Date(), load: 135.0, reps: [8, 8, 8], rpe: 6.0)
        ]

        let suggestion = service.generateLocalSuggestion(recentPerformance: performance)

        XCTAssertEqual(suggestion.progressionType, .increase)
        XCTAssertGreaterThan(suggestion.nextLoad, 135.0)
    }

    func testGenerateLocalSuggestion_HighRPE_SuggestsHoldOrDecrease() {
        let performance = [
            ExercisePerformance(date: Date(), load: 135.0, reps: [8, 7, 6], rpe: 9.5)
        ]

        let suggestion = service.generateLocalSuggestion(recentPerformance: performance)

        XCTAssertTrue(suggestion.progressionType == .hold || suggestion.progressionType == .decrease)
    }

    func testGenerateLocalSuggestion_DeloadActive() {
        let performance = [
            ExercisePerformance(date: Date(), load: 135.0, reps: [8, 8, 8], rpe: 7.0)
        ]

        let suggestion = service.generateLocalSuggestion(
            recentPerformance: performance,
            deloadActive: true,
            deloadReductionPct: 0.15
        )

        XCTAssertEqual(suggestion.progressionType, .deload)
        XCTAssertEqual(suggestion.nextLoad, 135.0 * 0.85, accuracy: 0.1)
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

        XCTAssertNotNil(service.suggestion?.analysis)
        XCTAssertEqual(service.suggestion?.analysis.trend, .improving)
        XCTAssertEqual(service.suggestion?.analysis.estimated1RM, 172.5)
        XCTAssertEqual(service.suggestion?.analysis.recentSessions, 3)
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

        XCTAssertNotNil(service.suggestion?.analysis)
        XCTAssertEqual(service.suggestion?.analysis.trend, .declining)
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

    func testPerformanceTrend_ColorUniqueness() {
        let colors = [
            PerformanceTrend.improving.color,
            PerformanceTrend.plateaued.color,
            PerformanceTrend.declining.color
        ]

        let uniqueColors = Set(colors.map { "\($0)" })
        XCTAssertEqual(uniqueColors.count, 3, "Each performance trend should have a unique color")
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

    func testPerformanceAnalysis_ZeroRecentSessions() {
        let analysis = PerformanceAnalysis(
            trend: .plateaued,
            estimated1RM: nil,
            velocityTrend: nil,
            fatigueImpact: nil,
            recentSessions: 0
        )

        XCTAssertEqual(analysis.recentSessions, 0)
        XCTAssertEqual(analysis.estimated1RMFormatted, "N/A")
    }

    func testPerformanceAnalysis_VeryHighEstimated1RM() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 500.0,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 10
        )

        XCTAssertEqual(analysis.estimated1RMFormatted, "500.0 lbs")
    }

    func testPerformanceAnalysis_DecimalEstimated1RM() {
        let analysis = PerformanceAnalysis(
            trend: .improving,
            estimated1RM: 172.75,
            velocityTrend: "stable",
            fatigueImpact: "low",
            recentSessions: 3
        )

        // Should round to 1 decimal place
        XCTAssertEqual(analysis.estimated1RMFormatted, "172.8 lbs")
    }
}
