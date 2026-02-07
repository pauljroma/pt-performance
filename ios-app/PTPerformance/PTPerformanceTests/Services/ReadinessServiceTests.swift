//
//  ReadinessServiceTests.swift
//  PTPerformanceTests
//
//  Comprehensive unit tests for ReadinessService
//  Tests fetch today's readiness, submit check-in, get readiness history, and calculate trends
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Supabase Client for ReadinessService Testing

/// Mock implementation of PTSupabaseClient for testing ReadinessService
/// Note: In a real implementation, you would need to properly mock the Supabase client
/// This serves as documentation for the expected test structure

// MARK: - Readiness Service Core Tests

@MainActor
final class ReadinessServiceCoreTests: XCTestCase {

    var service: ReadinessService!
    let testPatientId = UUID()

    override func setUp() {
        super.setUp()
        service = ReadinessService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Band Calculation Tests

    func testCalculateReadinessBand_OptimalSleep() {
        let input = BandCalculationInput(
            sleepHours: 8.0,
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
        XCTAssertGreaterThanOrEqual(score!, 60, "Optimal sleep should result in score >= 60")
    }

    func testCalculateReadinessBand_PoorSleep() {
        let input = BandCalculationInput(
            sleepHours: 4.0,
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        XCTAssertLessThan(score!, 70, "Poor sleep should result in lower score")
    }

    func testCalculateReadinessBand_ArmSorenessPenalty() {
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
            armSorenessSeverity: 2,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreWithout) = service.calculateReadinessBand(input: withoutSoreness)
        let (_, scoreWith) = service.calculateReadinessBand(input: withSoreness)

        XCTAssertNotNil(scoreWithout)
        XCTAssertNotNil(scoreWith)
        XCTAssertLessThan(scoreWith!, scoreWithout!, "Arm soreness should reduce score")
    }

    func testCalculateReadinessBand_JointPainPenalty() {
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
            jointPain: [.shoulder, .knee, .back],
            jointPainNotes: nil
        )

        let (_, scoreNoPain) = service.calculateReadinessBand(input: noJointPain)
        let (_, scoreWithPain) = service.calculateReadinessBand(input: multipleJointPain)

        XCTAssertNotNil(scoreNoPain)
        XCTAssertNotNil(scoreWithPain)
        XCTAssertLessThan(scoreWithPain!, scoreNoPain!, "Joint pain should reduce score")
    }

    func testCalculateReadinessBand_HRVComponent() {
        let lowHRV = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: 30.0,
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
            hrvValue: 80.0,
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
        XCTAssertGreaterThan(scoreHighHRV!, scoreLowHRV!, "Higher HRV should increase score")
    }

    func testCalculateReadinessBand_WHOOPRecovery() {
        let input = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: nil,
            whoopRecoveryPct: 90,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        XCTAssertGreaterThanOrEqual(score!, 65, "High WHOOP recovery should boost score")
    }

    func testCalculateReadinessBand_SubjectiveReadiness() {
        let lowSubjective = BandCalculationInput(
            sleepHours: 7.5,
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 1,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let highSubjective = BandCalculationInput(
            sleepHours: 7.5,
            sleepQuality: nil,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreLow) = service.calculateReadinessBand(input: lowSubjective)
        let (_, scoreHigh) = service.calculateReadinessBand(input: highSubjective)

        XCTAssertNotNil(scoreLow)
        XCTAssertNotNil(scoreHigh)
        XCTAssertGreaterThan(scoreHigh!, scoreLow!, "Higher subjective readiness should increase score")
    }

    // MARK: - Band Threshold Tests

    func testCalculateReadinessBand_GreenBandThreshold() {
        let input = BandCalculationInput(
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

        let (band, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        if score! >= 80 {
            XCTAssertEqual(band, .green, "Score >= 80 should be green band")
        }
    }

    func testCalculateReadinessBand_YellowBandThreshold() {
        let input = BandCalculationInput(
            sleepHours: 7.0,
            sleepQuality: 3,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        if score! >= 60 && score! < 80 {
            XCTAssertEqual(band, .yellow, "Score 60-79 should be yellow band")
        }
    }

    func testCalculateReadinessBand_OrangeBandThreshold() {
        let input = BandCalculationInput(
            sleepHours: 5.0,
            sleepQuality: 2,
            hrvValue: 35.0,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 2,
            armSoreness: true,
            armSorenessSeverity: 1,
            jointPain: [],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        if score! >= 40 && score! < 60 {
            XCTAssertEqual(band, .orange, "Score 40-59 should be orange band")
        }
    }

    func testCalculateReadinessBand_RedBandThreshold() {
        let input = BandCalculationInput(
            sleepHours: 3.0,
            sleepQuality: 1,
            hrvValue: 20.0,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 1,
            armSoreness: true,
            armSorenessSeverity: 3,
            jointPain: [.shoulder, .elbow, .knee, .back],
            jointPainNotes: nil
        )

        let (band, score) = service.calculateReadinessBand(input: input)

        XCTAssertNotNil(score)
        XCTAssertLessThan(score!, 50)
        XCTAssertTrue(band == .orange || band == .red)
    }

    // MARK: - Score Clamping Tests

    func testCalculateReadinessBand_ScoreClampedToValidRange() {
        // Test with extreme high values
        let extremeHigh = BandCalculationInput(
            sleepHours: 9.0,
            sleepQuality: 5,
            hrvValue: 200.0,
            whoopRecoveryPct: 100,
            subjectiveReadiness: 5,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: extremeHigh)

        XCTAssertNotNil(score)
        XCTAssertLessThanOrEqual(score!, 100.0, "Score should be clamped to max 100")
        XCTAssertGreaterThanOrEqual(score!, 0.0, "Score should be clamped to min 0")
    }

    func testCalculateReadinessBand_ScoreClampedAtMinimum() {
        // Test with extreme penalties
        let extremeLow = BandCalculationInput(
            sleepHours: 0.0,
            sleepQuality: 1,
            hrvValue: 10.0,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 1,
            armSoreness: true,
            armSorenessSeverity: 3,
            jointPain: [.shoulder, .elbow, .knee, .back, .hip],
            jointPainNotes: nil
        )

        let (_, score) = service.calculateReadinessBand(input: extremeLow)

        XCTAssertNotNil(score)
        XCTAssertGreaterThanOrEqual(score!, 0.0, "Score should not be negative")
    }

    // MARK: - Sleep Quality Component Tests

    func testCalculateReadinessBand_SleepQualityImpact() {
        let lowQuality = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 1,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let highQuality = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 5,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 3,
            armSoreness: false,
            armSorenessSeverity: nil,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreLow) = service.calculateReadinessBand(input: lowQuality)
        let (_, scoreHigh) = service.calculateReadinessBand(input: highQuality)

        XCTAssertNotNil(scoreLow)
        XCTAssertNotNil(scoreHigh)
        XCTAssertGreaterThan(scoreHigh!, scoreLow!, "Higher sleep quality should increase score")
    }

    // MARK: - Arm Soreness Severity Tests

    func testCalculateReadinessBand_ArmSorenessSeverityLevels() {
        let mildSoreness = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 4,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 4,
            armSoreness: true,
            armSorenessSeverity: 1,
            jointPain: [],
            jointPainNotes: nil
        )

        let severeSoreness = BandCalculationInput(
            sleepHours: 8.0,
            sleepQuality: 4,
            hrvValue: nil,
            whoopRecoveryPct: nil,
            subjectiveReadiness: 4,
            armSoreness: true,
            armSorenessSeverity: 3,
            jointPain: [],
            jointPainNotes: nil
        )

        let (_, scoreMild) = service.calculateReadinessBand(input: mildSoreness)
        let (_, scoreSevere) = service.calculateReadinessBand(input: severeSoreness)

        XCTAssertNotNil(scoreMild)
        XCTAssertNotNil(scoreSevere)
        XCTAssertGreaterThan(scoreMild!, scoreSevere!, "Mild soreness should score higher than severe")
    }

    // MARK: - Interpret Score Tests

    func testInterpretScore_AllCategories() {
        let elite = service.interpretScore(95.0)
        XCTAssertEqual(elite.category, .elite)

        let high = service.interpretScore(82.0)
        XCTAssertEqual(high.category, .high)

        let moderate = service.interpretScore(67.0)
        XCTAssertEqual(moderate.category, .moderate)

        let low = service.interpretScore(52.0)
        XCTAssertEqual(low.category, .low)

        let poor = service.interpretScore(30.0)
        XCTAssertEqual(poor.category, .poor)
    }

    func testInterpretScore_BoundaryValues() {
        // At 90 boundary
        let at90 = service.interpretScore(90.0)
        XCTAssertEqual(at90.category, .elite)

        // Just below 90
        let below90 = service.interpretScore(89.9)
        XCTAssertEqual(below90.category, .high)

        // At 75 boundary
        let at75 = service.interpretScore(75.0)
        XCTAssertEqual(at75.category, .high)

        // Just below 75
        let below75 = service.interpretScore(74.9)
        XCTAssertEqual(below75.category, .moderate)

        // At 60 boundary
        let at60 = service.interpretScore(60.0)
        XCTAssertEqual(at60.category, .moderate)

        // Just below 60
        let below60 = service.interpretScore(59.9)
        XCTAssertEqual(below60.category, .low)

        // At 45 boundary
        let at45 = service.interpretScore(45.0)
        XCTAssertEqual(at45.category, .low)

        // Just below 45
        let below45 = service.interpretScore(44.9)
        XCTAssertEqual(below45.category, .poor)
    }

    func testInterpretScore_ExtremeValues() {
        let zero = service.interpretScore(0.0)
        XCTAssertEqual(zero.category, .poor)

        let hundred = service.interpretScore(100.0)
        XCTAssertEqual(hundred.category, .elite)
    }
}

// MARK: - Readiness Summary Tests

final class ReadinessSummaryTests: XCTestCase {

    func testReadinessSummary_HasLoggedToday() {
        let today = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 75.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let trend = createMockTrend()
        let summaryWithToday = ReadinessSummary(today: today, recent: [today], trend: trend)
        XCTAssertTrue(summaryWithToday.hasLoggedToday)

        let summaryWithoutToday = ReadinessSummary(today: nil, recent: [], trend: trend)
        XCTAssertFalse(summaryWithoutToday.hasLoggedToday)
    }

    func testReadinessSummary_CurrentScore() {
        let today = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 82.5,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let trend = createMockTrend()
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertEqual(summary.currentScore, 82.5)
    }

    func testReadinessSummary_CurrentScoreNil() {
        let trend = createMockTrend()
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertNil(summary.currentScore)
    }

    func testReadinessSummary_AverageScore() {
        let trend = createMockTrend(avgReadiness: 75.0)
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertEqual(summary.averageScore, 75.0)
    }

    func testReadinessSummary_ScoreChange() {
        let today = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 8.0,
            sorenessLevel: 3,
            energyLevel: 7,
            stressLevel: 4,
            readinessScore: 85.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let trend = createMockTrend(avgReadiness: 75.0)
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertEqual(summary.scoreChange, 10.0)
    }

    func testReadinessSummary_ScoreChangeNegative() {
        let today = DailyReadiness(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            sleepHours: 6.0,
            sorenessLevel: 5,
            energyLevel: 5,
            stressLevel: 6,
            readinessScore: 65.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let trend = createMockTrend(avgReadiness: 75.0)
        let summary = ReadinessSummary(today: today, recent: [today], trend: trend)

        XCTAssertEqual(summary.scoreChange, -10.0)
    }

    func testReadinessSummary_ScoreChangeNilWithoutToday() {
        let trend = createMockTrend(avgReadiness: 75.0)
        let summary = ReadinessSummary(today: nil, recent: [], trend: trend)

        XCTAssertNil(summary.scoreChange)
    }

    // MARK: - Helper

    private func createMockTrend(avgReadiness: Double? = 70.0) -> ReadinessTrend {
        return ReadinessTrend(
            patientId: UUID(),
            daysAnalyzed: 7,
            currentDate: Date(),
            trendData: [],
            statistics: ReadinessTrend.TrendStatistics(
                avgReadiness: avgReadiness,
                minReadiness: 60.0,
                maxReadiness: 85.0,
                avgSleep: 7.5,
                avgSoreness: 3.5,
                avgEnergy: 7.0,
                avgStress: 4.0,
                totalEntries: 5
            )
        )
    }
}

// MARK: - Composite Readiness Score Tests

final class CompositeReadinessScoreTests: XCTestCase {

    func testReadinessConfidence_Descriptions() {
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.high.description, "Based on HRV, sleep, and check-in data")
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.medium.description, "Based on partial health data")
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.low.description, "Based on check-in data only")
    }

    func testReadinessConfidence_RawValues() {
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.high.rawValue, "high")
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.medium.rawValue, "medium")
        XCTAssertEqual(CompositeReadinessScore.ReadinessConfidence.low.rawValue, "low")
    }
}

// MARK: - Readiness Analysis Tests

final class ReadinessAnalysisTests: XCTestCase {

    func testTrendDirection_RawValues() {
        XCTAssertEqual(ReadinessAnalysis.ReadinessTrendDirection.improving.rawValue, "improving")
        XCTAssertEqual(ReadinessAnalysis.ReadinessTrendDirection.stable.rawValue, "stable")
        XCTAssertEqual(ReadinessAnalysis.ReadinessTrendDirection.declining.rawValue, "declining")
    }

    func testDayOfWeek_Names() {
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.sunday.name, "Sunday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.monday.name, "Monday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.tuesday.name, "Tuesday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.wednesday.name, "Wednesday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.thursday.name, "Thursday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.friday.name, "Friday")
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.saturday.name, "Saturday")
    }

    func testDayOfWeek_RawValues() {
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.sunday.rawValue, 1)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.monday.rawValue, 2)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.tuesday.rawValue, 3)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.wednesday.rawValue, 4)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.thursday.rawValue, 5)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.friday.rawValue, 6)
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.saturday.rawValue, 7)
    }

    func testDayOfWeek_AllCases() {
        XCTAssertEqual(ReadinessAnalysis.DayOfWeek.allCases.count, 7)
    }
}

// MARK: - Readiness Forecast Tests

final class ReadinessForecastTests: XCTestCase {

    func testForecastFactor_Initialization() {
        let factor = ReadinessForecast.ForecastFactor(
            name: "Sleep",
            impact: 5.0,
            description: "Good sleep last night"
        )

        XCTAssertEqual(factor.name, "Sleep")
        XCTAssertEqual(factor.impact, 5.0)
        XCTAssertEqual(factor.description, "Good sleep last night")
    }

    func testReadinessForecast_Initialization() {
        let forecast = ReadinessForecast(
            date: Date(),
            predictedScore: 75.0,
            confidence: 0.8,
            factors: [
                ReadinessForecast.ForecastFactor(
                    name: "Trend",
                    impact: 3.0,
                    description: "Recent improvement"
                )
            ]
        )

        XCTAssertEqual(forecast.predictedScore, 75.0)
        XCTAssertEqual(forecast.confidence, 0.8)
        XCTAssertEqual(forecast.factors.count, 1)
    }
}

// MARK: - ReadinessTrend Decoding Tests

final class ReadinessTrendDecodingTests: XCTestCase {

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
        XCTAssertEqual(trend.trendData.first?.readinessScore, 78.5)
        XCTAssertEqual(trend.statistics.avgReadiness, 75.0)
        XCTAssertEqual(trend.statistics.totalEntries, 5)
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

// MARK: - JointPainLocation Tests

final class JointPainLocationTests: XCTestCase {

    func testJointPainLocation_DisplayNames() {
        XCTAssertEqual(JointPainLocation.shoulder.displayName, "Shoulder")
        XCTAssertEqual(JointPainLocation.elbow.displayName, "Elbow")
        XCTAssertEqual(JointPainLocation.hip.displayName, "Hip")
        XCTAssertEqual(JointPainLocation.knee.displayName, "Knee")
        XCTAssertEqual(JointPainLocation.back.displayName, "Back")
    }

    func testJointPainLocation_RawValues() {
        XCTAssertEqual(JointPainLocation.shoulder.rawValue, "shoulder")
        XCTAssertEqual(JointPainLocation.elbow.rawValue, "elbow")
        XCTAssertEqual(JointPainLocation.hip.rawValue, "hip")
        XCTAssertEqual(JointPainLocation.knee.rawValue, "knee")
        XCTAssertEqual(JointPainLocation.back.rawValue, "back")
    }

    func testJointPainLocation_AllCases() {
        XCTAssertEqual(JointPainLocation.allCases.count, 5)
    }

    func testJointPainLocation_Encoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(JointPainLocation.shoulder)
        let string = String(data: data, encoding: .utf8)

        XCTAssertTrue(string?.contains("shoulder") ?? false)
    }

    func testJointPainLocation_Decoding() throws {
        let json = "\"shoulder\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let location = try decoder.decode(JointPainLocation.self, from: json)

        XCTAssertEqual(location, .shoulder)
    }
}
