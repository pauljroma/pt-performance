//
//  FatigueAdjustmentTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueAdjustment model
//  Tests factory method with all fatigue bands and reduction calculations
//

import XCTest
@testable import PTPerformance

final class FatigueAdjustmentTests: XCTestCase {

    // MARK: - Test Helpers

    private func createFatigueAccumulation(
        band: FatigueBand,
        deloadRecommended: Bool = false
    ) -> FatigueAccumulation {
        FatigueAccumulation(
            id: UUID(),
            patientId: UUID(),
            calculationDate: Date(),
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
            fatigueBand: band,
            deloadRecommended: deloadRecommended,
            deloadUrgency: .suggested,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Factory Method Tests - All Fatigue Bands

    func testFatigueAdjustment_FromLowFatigue_ReturnsNil() {
        let fatigue = createFatigueAccumulation(band: .low)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)

        XCTAssertNil(adjustment, "Low fatigue should return nil adjustment")
    }

    func testFatigueAdjustment_FromModerateFatigue_ReturnsAdjustment() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.fatigueBand, .moderate)
    }

    func testFatigueAdjustment_FromHighFatigue_ReturnsAdjustment() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.fatigueBand, .high)
    }

    func testFatigueAdjustment_FromCriticalFatigue_ReturnsAdjustment() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)

        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.fatigueBand, .critical)
    }

    // MARK: - Load Reduction Tests

    func testFatigueAdjustment_ModerateFatigue_LoadReduction() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPct, 0.1, "Moderate fatigue should have 10% load reduction")
    }

    func testFatigueAdjustment_HighFatigue_LoadReduction() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPct, 0.3, "High fatigue should have 30% load reduction")
    }

    func testFatigueAdjustment_CriticalFatigue_LoadReduction() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPct, 0.5, "Critical fatigue should have 50% load reduction")
    }

    // MARK: - Volume Reduction Tests

    func testFatigueAdjustment_ModerateFatigue_VolumeReduction() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPct, 0.1, "Moderate fatigue should have 10% volume reduction")
    }

    func testFatigueAdjustment_HighFatigue_VolumeReduction() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPct, 0.25, "High fatigue should have 25% volume reduction")
    }

    func testFatigueAdjustment_CriticalFatigue_VolumeReduction() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPct, 0.4, "Critical fatigue should have 40% volume reduction")
    }

    // MARK: - Load Reduction Percent (Integer) Tests

    func testFatigueAdjustment_LoadReductionPercent_Moderate() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPercent, 10)
    }

    func testFatigueAdjustment_LoadReductionPercent_High() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPercent, 30)
    }

    func testFatigueAdjustment_LoadReductionPercent_Critical() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.loadReductionPercent, 50)
    }

    // MARK: - Volume Reduction Percent (Integer) Tests

    func testFatigueAdjustment_VolumeReductionPercent_Moderate() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPercent, 10)
    }

    func testFatigueAdjustment_VolumeReductionPercent_High() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPercent, 25)
    }

    func testFatigueAdjustment_VolumeReductionPercent_Critical() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertEqual(adjustment.volumeReductionPercent, 40)
    }

    // MARK: - IsActive Tests

    func testFatigueAdjustment_IsActive_WhenLoadReductionPositive() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertTrue(adjustment.isActive)
    }

    func testFatigueAdjustment_IsActive_WhenVolumeReductionPositive() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertTrue(adjustment.isActive)
    }

    func testFatigueAdjustment_IsActive_AllNonLowBands() {
        for band in FatigueBand.allCases {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)

            if band == .low {
                XCTAssertNil(adjustment)
            } else {
                XCTAssertTrue(adjustment!.isActive, "Adjustment for \(band) should be active")
            }
        }
    }

    // MARK: - Reason Tests

    func testFatigueAdjustment_Reason_ModerateFatigue() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertFalse(adjustment.reason.isEmpty)
        XCTAssertTrue(adjustment.reason.lowercased().contains("moderate") ||
                     adjustment.reason.lowercased().contains("fatigue") ||
                     adjustment.reason.lowercased().contains("recovery"))
    }

    func testFatigueAdjustment_Reason_HighFatigue() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertFalse(adjustment.reason.isEmpty)
        XCTAssertTrue(adjustment.reason.lowercased().contains("high") ||
                     adjustment.reason.lowercased().contains("reduce") ||
                     adjustment.reason.lowercased().contains("recovery"))
    }

    func testFatigueAdjustment_Reason_CriticalFatigue() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertFalse(adjustment.reason.isEmpty)
        XCTAssertTrue(adjustment.reason.lowercased().contains("critical") ||
                     adjustment.reason.lowercased().contains("significant") ||
                     adjustment.reason.lowercased().contains("recovery"))
    }

    // MARK: - IsDeloadWeek Tests

    func testFatigueAdjustment_IsDeloadWeek_WhenRecommended() {
        let fatigue = createFatigueAccumulation(band: .critical, deloadRecommended: true)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertTrue(adjustment.isDeloadWeek)
    }

    func testFatigueAdjustment_IsDeloadWeek_WhenNotRecommended() {
        let fatigue = createFatigueAccumulation(band: .high, deloadRecommended: false)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertFalse(adjustment.isDeloadWeek)
    }

    func testFatigueAdjustment_IsDeloadWeek_CarriedFromFatigueAccumulation() {
        // Test with deload recommended
        let fatigueWithDeload = createFatigueAccumulation(band: .moderate, deloadRecommended: true)
        let adjustmentWithDeload = FatigueAdjustment.from(fatigue: fatigueWithDeload)!
        XCTAssertTrue(adjustmentWithDeload.isDeloadWeek)

        // Test without deload recommended
        let fatigueWithoutDeload = createFatigueAccumulation(band: .moderate, deloadRecommended: false)
        let adjustmentWithoutDeload = FatigueAdjustment.from(fatigue: fatigueWithoutDeload)!
        XCTAssertFalse(adjustmentWithoutDeload.isDeloadWeek)
    }

    // MARK: - Progression Tests

    func testFatigueAdjustment_ProgressiveReduction() {
        // Load reduction should increase with fatigue severity
        let moderateFatigue = createFatigueAccumulation(band: .moderate)
        let highFatigue = createFatigueAccumulation(band: .high)
        let criticalFatigue = createFatigueAccumulation(band: .critical)

        let moderateAdjustment = FatigueAdjustment.from(fatigue: moderateFatigue)!
        let highAdjustment = FatigueAdjustment.from(fatigue: highFatigue)!
        let criticalAdjustment = FatigueAdjustment.from(fatigue: criticalFatigue)!

        // Load reductions should increase
        XCTAssertLessThan(moderateAdjustment.loadReductionPct, highAdjustment.loadReductionPct)
        XCTAssertLessThan(highAdjustment.loadReductionPct, criticalAdjustment.loadReductionPct)

        // Volume reductions should increase
        XCTAssertLessThan(moderateAdjustment.volumeReductionPct, highAdjustment.volumeReductionPct)
        XCTAssertLessThan(highAdjustment.volumeReductionPct, criticalAdjustment.volumeReductionPct)
    }

    // MARK: - Edge Case Tests

    func testFatigueAdjustment_ReductionValues_AreInValidRange() {
        for band in FatigueBand.allCases {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)

            if let adj = adjustment {
                // Load reduction should be 0.0 to 1.0
                XCTAssertGreaterThanOrEqual(adj.loadReductionPct, 0.0)
                XCTAssertLessThanOrEqual(adj.loadReductionPct, 1.0)

                // Volume reduction should be 0.0 to 1.0
                XCTAssertGreaterThanOrEqual(adj.volumeReductionPct, 0.0)
                XCTAssertLessThanOrEqual(adj.volumeReductionPct, 1.0)

                // Percent values should match
                XCTAssertEqual(adj.loadReductionPercent, Int(adj.loadReductionPct * 100))
                XCTAssertEqual(adj.volumeReductionPercent, Int(adj.volumeReductionPct * 100))
            }
        }
    }

    func testFatigueAdjustment_AllBandsHaveExpectedReductions() {
        // Verify each band has the documented reduction percentages
        let expectedReductions: [(FatigueBand, Double, Double)] = [
            (.moderate, 0.1, 0.1),   // 10% load, 10% volume
            (.high, 0.3, 0.25),      // 30% load, 25% volume
            (.critical, 0.5, 0.4)    // 50% load, 40% volume
        ]

        for (band, expectedLoad, expectedVolume) in expectedReductions {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertEqual(adjustment.loadReductionPct, expectedLoad,
                           "Load reduction for \(band) should be \(expectedLoad)")
            XCTAssertEqual(adjustment.volumeReductionPct, expectedVolume,
                           "Volume reduction for \(band) should be \(expectedVolume)")
        }
    }

    // MARK: - FatigueBand Property Tests

    func testFatigueAdjustment_FatigueBand_MatchesInput() {
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertEqual(adjustment.fatigueBand, band,
                           "Adjustment fatigueBand should match input fatigue band")
        }
    }
}
