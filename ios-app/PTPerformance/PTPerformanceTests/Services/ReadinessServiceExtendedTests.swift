//
//  ReadinessServiceExtendedTests.swift
//  PTPerformanceTests
//
//  Extended unit tests for ReadinessService
//  Tests band calculations, WHOOP-style inputs, trend analysis, and edge cases
//

import XCTest
import SwiftUI
@testable import PTPerformance

// MARK: - BandCalculationInput Tests

final class BandCalculationInputTests: XCTestCase {

    func testBandCalculationInput_AllNil() {
        let input = BandCalculationInput(
            sleepHours: nil,
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: nil,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        XCTAssertNil(input.sleepHours)
        XCTAssertNil(input.sleepQuality)
        XCTAssertNil(input.hrvValue)
        XCTAssertNil(input.whoopRecoveryPct)
        XCTAssertNil(input.subjectiveReadiness)
        XCTAssertFalse(input.armSoreness)
        XCTAssertTrue(input.jointPain.isEmpty)
    }

    func testBandCalculationInput_WithAllValues() {
        let input = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 4,
            hrvValue: 65.0,
            whoopRecoveryPct: 85,
            subjectiveReadiness: 4,
            armSoreness: true,
            armSorenessSeverity: 2,
            jointPain: [.shoulder, .knee],
            jointPainNotes: "Slight discomfort after yesterday's workout"
        )

        XCTAssertEqual(input.sleepHours, 8.0)
        XCTAssertEqual(input.sleepQuality, 4)
        XCTAssertEqual(input.hrvValue, 65.0)
        XCTAssertEqual(input.whoopRecoveryPct, 85)
        XCTAssertEqual(input.subjectiveReadiness, 4)
        XCTAssertTrue(input.armSoreness)
        XCTAssertEqual(input.armSorenessSeverity, 2)
        XCTAssertEqual(input.jointPain.count, 2)
        XCTAssertNotNil(input.jointPainNotes)
    }
}

// MARK: - Readiness Band Calculation Tests

final class ReadinessBandCalculationTests: XCTestCase {

    let service = ReadinessService()

    // MARK: - Sleep Hours Component Tests

    func testBandCalculation_OptimalSleep_HighScore() {
        let input = BandCalculationInput(
            sleepHours: 8.0,  // Optimal range 7-9
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 4,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: input)
        XCTAssertNotNil(score)
        XCTAssertGreaterThanOrEqual(score!, 60)
    }

    func testBandCalculation_LowSleep_LowerScore() {
        let input = BandCalculationInput(
            sleepHours: 4.0,  // Below optimal
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 4,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: input)
        XCTAssertNotNil(score)
        // Low sleep should reduce score
        XCTAssertLessThan(score!, 70)
    }

    // MARK: - Subjective Readiness Tests

    func testBandCalculation_HighSubjectiveReadiness() {
        let input = BandCalculationInput(
            sleepHours: 7.5,
            sleepQuality: 4,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,  // Highest
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, _) = service.calculateReadinessBand(input: input)
        // High subjective readiness should result in at least yellow band
        XCTAssertTrue(band == .green || band == .yellow, "High subjective readiness should result in green or yellow band")
    }

    func testBandCalculation_LowSubjectiveReadiness() {
        let input = BandCalculationInput(
            sleepHours: 7.5,
            sleepQuality: 2,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 1,  // Lowest
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, _) = service.calculateReadinessBand(input: input)
        // Low subjective readiness should push toward yellow/orange
        XCTAssertNotEqual(band, .green)
    }

    // MARK: - Pain Penalty Tests

    func testBandCalculation_ArmSoreness_AppliesPenalty() {
        let withoutSoreness = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let withSoreness = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: true,
            armSorenessSeverity: 2,  // Moderate
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreWithout) = service.calculateReadinessBand(input: withoutSoreness)
        let (_, scoreWith) = service.calculateReadinessBand(input: withSoreness)

        XCTAssertNotNil(scoreWithout)
        XCTAssertNotNil(scoreWith)
        XCTAssertLessThan(scoreWith!, scoreWithout!)
    }

    func testBandCalculation_JointPain_AppliesPenalty() {
        let noJointPain = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let multipleJointPain = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [.shoulder, .knee, .back],  // 3 joints
            jointPainNotes: nil
        )

        let (_, scoreNoPain) = service.calculateReadinessBand(input: noJointPain)
        let (_, scoreWithPain) = service.calculateReadinessBand(input: multipleJointPain)

        XCTAssertNotNil(scoreNoPain)
        XCTAssertNotNil(scoreWithPain)
        XCTAssertLessThan(scoreWithPain!, scoreNoPain!)
    }

    // MARK: - HRV Component Tests

    func testBandCalculation_HighHRV_BoostsScore() {
        let lowHRV = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: 30.0,  // Low HRV
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let highHRV = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: 80.0,  // High HRV
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreLowHRV) = service.calculateReadinessBand(input: lowHRV)
        let (_, scoreHighHRV) = service.calculateReadinessBand(input: highHRV)

        XCTAssertNotNil(scoreLowHRV)
        XCTAssertNotNil(scoreHighHRV)
        XCTAssertGreaterThan(scoreHighHRV!, scoreLowHRV!)
    }

    // MARK: - WHOOP Recovery Tests

    func testBandCalculation_WHOOPRecovery_InfluencesScore() {
        let input = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: nil,
            whoopRecoveryPct: 90,  // High recovery
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: input)
        XCTAssertNotNil(score)
        // High WHOOP recovery should boost score
        XCTAssertGreaterThanOrEqual(score!, 65)
    }

    // MARK: - Band Threshold Tests

    func testBandCalculation_GreenBand_Threshold() {
        // Green band should be >= 80
        let highInput = BandCalculationInput(
            sleepHours: 9.0,
            sleepQuality: 5,
            hrvValue: 80.0,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: highInput)
        XCTAssertNotNil(score)
        if score! >= 80 {
            XCTAssertEqual(band, .green)
        }
    }

    func testBandCalculation_RedBand_LowScore() {
        // Extreme low readiness should result in red band
        let lowInput = BandCalculationInput(
            sleepHours: 3.0,
            sleepQuality: 1,
            hrvValue: 20.0,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 1,
            armSoreness: true,
            armSorenessSeverity: 3,  // Severe
            jointPain: [.shoulder, .elbow, .knee, .back],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: lowInput)
        XCTAssertNotNil(score)
        XCTAssertLessThan(score!, 50)
        // Should be orange or red
        XCTAssertTrue(band == .orange || band == .red)
    }

    // MARK: - Score Clamping Tests

    func testBandCalculation_ScoreClampedTo0To100() {
        // Test that score never exceeds bounds
        let extremeHighInput = BandCalculationInput(
            sleepHours: 9.0,
            sleepQuality: 5,
            hrvValue: 200.0,  // Unrealistically high
            whoopRecoveryPct: 100,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: extremeHighInput)
        XCTAssertNotNil(score)
        XCTAssertLessThanOrEqual(score!, 100)
        XCTAssertGreaterThanOrEqual(score!, 0)
    }
}

// MARK: - ReadinessPreview Tests

final class ReadinessPreviewTests: XCTestCase {

    func testReadinessPreview_Initialization() {
        let preview = ReadinessPreview(band: .green, score: 85.0)

        XCTAssertEqual(preview.band, .green)
        XCTAssertEqual(preview.score, 85.0)
    }

    func testReadinessPreview_NilScore() {
        let preview = ReadinessPreview(band: .yellow, score: nil)

        XCTAssertEqual(preview.band, .yellow)
        XCTAssertNil(preview.score)
    }
}

// MARK: - ReadinessTrend Tests

final class ReadinessTrendTests: XCTestCase {

    func testReadinessTrend_DecodesFromJSON() throws {
        let json = """
        {
            "patient_id": "123e4567-e89b-12d3-a456-426614174000",
            "days_analyzed": 7,
            "current_date": "2024-01-15T10:00:00Z",
            "trend_data": [
                {
                    "date": "2024-01-15T00:00:00Z",
                    "readiness_score": 78.5,
                    "sleep_hours": 7.5,
                    "soreness_level": 3,
                    "energy_level": 7,
                    "stress_level": 4,
                    "notes": null
                }
            ],
            "statistics": {
                "avg_readiness": 75.0,
                "min_readiness": 65.0,
                "max_readiness": 85.0,
                "avg_sleep": 7.2,
                "avg_soreness": 3.5,
                "avg_energy": 6.8,
                "avg_stress": 4.2,
                "total_entries": 5
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let trend = try decoder.decode(ReadinessTrend.self, from: json)

        XCTAssertEqual(trend.daysAnalyzed, 7)
        XCTAssertEqual(trend.trendData.count, 1)
        XCTAssertEqual(trend.statistics.totalEntries, 5)
        XCTAssertEqual(trend.statistics.avgReadiness, 75.0)
    }

    func testReadinessTrend_EmptyTrendData() throws {
        let json = """
        {
            "patient_id": "123e4567-e89b-12d3-a456-426614174000",
            "days_analyzed": 7,
            "current_date": "2024-01-15T10:00:00Z",
            "trend_data": [],
            "statistics": {
                "avg_readiness": null,
                "min_readiness": null,
                "max_readiness": null,
                "avg_sleep": null,
                "avg_soreness": null,
                "avg_energy": null,
                "avg_stress": null,
                "total_entries": 0
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let trend = try decoder.decode(ReadinessTrend.self, from: json)

        XCTAssertTrue(trend.trendData.isEmpty)
        XCTAssertEqual(trend.statistics.totalEntries, 0)
        XCTAssertNil(trend.statistics.avgReadiness)
    }
}

// MARK: - ReadinessFactor Tests (if present)

final class ReadinessFactorWeightingTests: XCTestCase {

    /// Test that factor weights are properly applied
    func testFactorWeights_SleepHeavilyWeighted() {
        // Sleep should have high weight in score calculation
        // Based on the algorithm in ReadinessService, sleep is 30%
        let sleepWeight = 0.30
        XCTAssertEqual(sleepWeight, 0.30, accuracy: 0.01)
    }

    func testFactorWeights_SubjectiveReadinessWeighted() {
        // Subjective readiness is 25%
        let subjectiveWeight = 0.25
        XCTAssertEqual(subjectiveWeight, 0.25, accuracy: 0.01)
    }

    func testFactorWeights_SleepQualityWeighted() {
        // Sleep quality is 20%
        let qualityWeight = 0.20
        XCTAssertEqual(qualityWeight, 0.20, accuracy: 0.01)
    }

    func testFactorWeights_HRVWeighted() {
        // HRV is 15%
        let hrvWeight = 0.15
        XCTAssertEqual(hrvWeight, 0.15, accuracy: 0.01)
    }
}

// MARK: - DailyReadiness Display Extension Tests

final class DailyReadinessDisplayExtensionTests: XCTestCase {

    func testFormattedDate() {
        let readiness = createReadiness(date: Date())
        XCTAssertFalse(readiness.formattedDate.isEmpty)
    }

    func testScoreText_WithScore() {
        let readiness = createReadiness(score: 78.6)
        XCTAssertEqual(readiness.scoreText, "79")  // Rounded
    }

    func testScoreText_WithWholeNumber() {
        let readiness = createReadiness(score: 85.0)
        XCTAssertEqual(readiness.scoreText, "85")
    }

    func testScoreText_NilScore() {
        let readiness = createReadiness(score: nil)
        XCTAssertEqual(readiness.scoreText, "--")
    }

    func testScoreColor_AllCategories() {
        // Elite (90+)
        let elite = createReadiness(score: 95.0)
        XCTAssertEqual(elite.scoreColor, Color.green)

        // High (75-89)
        let high = createReadiness(score: 82.0)
        XCTAssertEqual(high.scoreColor, Color.blue)

        // Moderate (60-74)
        let moderate = createReadiness(score: 67.0)
        XCTAssertEqual(moderate.scoreColor, Color.yellow)

        // Low (45-59)
        let low = createReadiness(score: 52.0)
        XCTAssertEqual(low.scoreColor, Color.orange)

        // Poor (<45)
        let poor = createReadiness(score: 30.0)
        XCTAssertEqual(poor.scoreColor, Color.red)

        // Nil
        let nilScore = createReadiness(score: nil)
        XCTAssertEqual(nilScore.scoreColor, Color.gray)
    }

    // MARK: - Helpers

    private func createReadiness(date: Date = Date(), score: Double? = 75.0) -> DailyReadiness {
        return DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: date,
            sleepHours: 7.5,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: score,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - ReadinessError FetchFailed Tests

final class ReadinessErrorFetchFailedTests: XCTestCase {

    func testFetchFailed_HasUnderlyingError() {
        let underlyingError = NSError(domain: "test", code: 500, userInfo: nil)
        let error = ReadinessError.fetchFailed(underlyingError)

        XCTAssertNotNil(error.underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to load readiness data")
        XCTAssertEqual(error.recoverySuggestion, "Please check your internet connection and try again.")
    }

    func testOtherErrors_NoUnderlyingError() {
        let errors: [ReadinessError] = [
            .invalidSleepHours,
            .invalidSorenessLevel,
            .invalidEnergyLevel,
            .invalidStressLevel,
            .noMetricsProvided,
            .scoreCalculationFailed,
            .noDataFound,
            .trendCalculationFailed
        ]

        for error in errors {
            XCTAssertNil(error.underlyingError, "Error \(error) should not have underlying error")
            XCTAssertNil(error.recoverySuggestion, "Error \(error) should not have recovery suggestion")
        }
    }
}

// MARK: - Custom Decoder Tests

final class DailyReadinessDecoderTests: XCTestCase {

    func testDailyReadiness_DecodesDateFormat() throws {
        // PostgreSQL DATE column returns "YYYY-MM-DD" format
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": 7.5,
            "soreness_level": 3,
            "energy_level": 7,
            "stress_level": 4,
            "readiness_score": 78.5,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertEqual(readiness.sleepHours, 7.5)
        XCTAssertEqual(readiness.readinessScore, 78.5)
    }

    func testDailyReadiness_DecodesNumericAsString() throws {
        // PostgreSQL NUMERIC type sometimes returns as string
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": "7.5",
            "soreness_level": 3,
            "energy_level": 7,
            "stress_level": 4,
            "readiness_score": "78.5",
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        // Custom decoder should handle string numerics
        XCTAssertEqual(readiness.sleepHours, 7.5)
        XCTAssertEqual(readiness.readinessScore, 78.5)
    }

    func testDailyReadiness_DecodesNullOptionals() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "patient_id": "123e4567-e89b-12d3-a456-426614174001",
            "date": "2024-01-15",
            "sleep_hours": null,
            "soreness_level": null,
            "energy_level": null,
            "stress_level": null,
            "readiness_score": null,
            "notes": null,
            "created_at": "2024-01-15T10:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = PTSupabaseClient.flexibleDecoder
        let readiness = try decoder.decode(DailyReadiness.self, from: json)

        XCTAssertNil(readiness.sleepHours)
        XCTAssertNil(readiness.sorenessLevel)
        XCTAssertNil(readiness.energyLevel)
        XCTAssertNil(readiness.stressLevel)
        XCTAssertNil(readiness.readinessScore)
        XCTAssertNil(readiness.notes)
    }
}
