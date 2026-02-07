//
//  FatigueAdjustmentTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueAdjustment model
//  Tests factory method with all fatigue bands, reduction calculations,
//  isActive computed property, and round to nearest 5 logic
//

import XCTest
@testable import PTPerformance

final class FatigueAdjustmentTests: XCTestCase {

    // MARK: - Test Helpers

    private func createFatigueAccumulation(
        band: FatigueBand,
        deloadRecommended: Bool = false,
        fatigueScore: Double = 55.0
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
            fatigueScore: fatigueScore,
            fatigueBand: band,
            deloadRecommended: deloadRecommended,
            deloadUrgency: .suggested,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createActiveDeloadPeriod(
        loadReductionPct: Double = 0.30,
        volumeReductionPct: Double = 0.40
    ) -> ActiveDeloadPeriod {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 4, to: Date()) ?? Date()

        return ActiveDeloadPeriod(
            id: UUID(),
            patientId: UUID(),
            recommendationId: UUID(),
            startDate: startDate,
            endDate: endDate,
            loadReductionPct: loadReductionPct,
            volumeReductionPct: volumeReductionPct,
            focus: "Recovery and mobility work",
            isActive: true,
            createdAt: startDate
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

    func testFatigueAdjustment_FromAllBands_ConsistentBehavior() {
        for band in FatigueBand.allCases {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)

            if band == .low {
                XCTAssertNil(adjustment, "Low band should not produce adjustment")
            } else {
                XCTAssertNotNil(adjustment, "\(band) band should produce adjustment")
                XCTAssertEqual(adjustment?.fatigueBand, band)
            }
        }
    }

    // MARK: - Factory Method From Deload Period Tests

    func testFatigueAdjustment_FromDeloadPeriod_ReturnsAdjustment() {
        let deload = createActiveDeloadPeriod()
        let adjustment = FatigueAdjustment.from(deload: deload)

        XCTAssertNotNil(adjustment)
        XCTAssertTrue(adjustment.isDeloadWeek)
    }

    func testFatigueAdjustment_FromDeloadPeriod_UsesDeloadReductions() {
        let deload = createActiveDeloadPeriod(loadReductionPct: 0.35, volumeReductionPct: 0.45)
        let adjustment = FatigueAdjustment.from(deload: deload)

        XCTAssertEqual(adjustment.loadReductionPct, 0.35)
        XCTAssertEqual(adjustment.volumeReductionPct, 0.45)
    }

    func testFatigueAdjustment_FromDeloadPeriod_SetsModerateBand() {
        let deload = createActiveDeloadPeriod()
        let adjustment = FatigueAdjustment.from(deload: deload)

        XCTAssertEqual(adjustment.fatigueBand, .moderate,
                      "Deload period should use moderate band")
    }

    func testFatigueAdjustment_FromDeloadPeriod_IsAlwaysDeloadWeek() {
        let deload = createActiveDeloadPeriod()
        let adjustment = FatigueAdjustment.from(deload: deload)

        XCTAssertTrue(adjustment.isDeloadWeek)
        XCTAssertTrue(adjustment.isDeload)
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

    func testFatigueAdjustment_LoadReduction_NeverExceedsOne() {
        for band in FatigueBand.allCases {
            let fatigue = createFatigueAccumulation(band: band)
            if let adjustment = FatigueAdjustment.from(fatigue: fatigue) {
                XCTAssertLessThanOrEqual(adjustment.loadReductionPct, 1.0,
                                        "Load reduction should never exceed 100%")
                XCTAssertGreaterThanOrEqual(adjustment.loadReductionPct, 0.0,
                                           "Load reduction should never be negative")
            }
        }
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

    func testFatigueAdjustment_VolumeReduction_NeverExceedsOne() {
        for band in FatigueBand.allCases {
            let fatigue = createFatigueAccumulation(band: band)
            if let adjustment = FatigueAdjustment.from(fatigue: fatigue) {
                XCTAssertLessThanOrEqual(adjustment.volumeReductionPct, 1.0,
                                        "Volume reduction should never exceed 100%")
                XCTAssertGreaterThanOrEqual(adjustment.volumeReductionPct, 0.0,
                                           "Volume reduction should never be negative")
            }
        }
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

    func testFatigueAdjustment_LoadReductionPercent_MatchesDecimal() {
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertEqual(adjustment.loadReductionPercent, Int(adjustment.loadReductionPct * 100),
                          "Integer percent should match decimal * 100")
        }
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

    func testFatigueAdjustment_VolumeReductionPercent_MatchesDecimal() {
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertEqual(adjustment.volumeReductionPercent, Int(adjustment.volumeReductionPct * 100),
                          "Integer percent should match decimal * 100")
        }
    }

    // MARK: - IsActive Computed Property Tests

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

    func testFatigueAdjustment_IsActive_WhenBothReductionsPositive() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Both should be positive
        XCTAssertGreaterThan(adjustment.loadReductionPct, 0)
        XCTAssertGreaterThan(adjustment.volumeReductionPct, 0)
        XCTAssertTrue(adjustment.isActive)
    }

    func testFatigueAdjustment_IsActive_LogicalOR() {
        // Test that isActive returns true if EITHER reduction is positive
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            let expectedActive = adjustment.loadReductionPct > 0 || adjustment.volumeReductionPct > 0
            XCTAssertEqual(adjustment.isActive, expectedActive)
        }
    }

    // MARK: - IsDeload Alias Tests

    func testFatigueAdjustment_IsDeload_AliasForIsDeloadWeek() {
        let fatigue = createFatigueAccumulation(band: .critical, deloadRecommended: true)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // isDeload should equal isDeloadWeek
        XCTAssertEqual(adjustment.isDeload, adjustment.isDeloadWeek)
    }

    func testFatigueAdjustment_IsDeload_WhenNotDeloadWeek() {
        let fatigue = createFatigueAccumulation(band: .high, deloadRecommended: false)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        XCTAssertFalse(adjustment.isDeload)
        XCTAssertEqual(adjustment.isDeload, adjustment.isDeloadWeek)
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

    func testFatigueAdjustment_Reason_IsNotEmpty_AllBands() {
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertFalse(adjustment.reason.isEmpty,
                          "Reason should not be empty for \(band)")
            XCTAssertGreaterThan(adjustment.reason.count, 10,
                                "Reason should be descriptive for \(band)")
        }
    }

    func testFatigueAdjustment_Reason_FromDeloadPeriod() {
        let deload = createActiveDeloadPeriod()
        let adjustment = FatigueAdjustment.from(deload: deload)

        XCTAssertFalse(adjustment.reason.isEmpty)
        XCTAssertTrue(adjustment.reason.lowercased().contains("deload") ||
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

    func testFatigueAdjustment_IsDeloadWeek_IndependentOfBand() {
        // Deload can be recommended at any fatigue band
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigueWithDeload = createFatigueAccumulation(band: band, deloadRecommended: true)
            let adjustment = FatigueAdjustment.from(fatigue: fatigueWithDeload)!
            XCTAssertTrue(adjustment.isDeloadWeek, "Deload should be true when recommended for \(band)")
        }
    }

    // MARK: - Adjusted Load Calculation Tests

    func testFatigueAdjustment_AdjustedLoad_Moderate() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        let originalLoad = 100.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // 10% reduction means 90% of original
        XCTAssertEqual(adjustedLoad, 90.0, accuracy: 0.01)
    }

    func testFatigueAdjustment_AdjustedLoad_High() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        let originalLoad = 100.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // 30% reduction means 70% of original
        XCTAssertEqual(adjustedLoad, 70.0, accuracy: 0.01)
    }

    func testFatigueAdjustment_AdjustedLoad_Critical() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        let originalLoad = 100.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // 50% reduction means 50% of original
        XCTAssertEqual(adjustedLoad, 50.0, accuracy: 0.01)
    }

    func testFatigueAdjustment_AdjustedLoad_WithRealWeight() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Test with realistic weight: 225 lbs
        let originalLoad = 225.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // 30% reduction: 225 * 0.7 = 157.5
        XCTAssertEqual(adjustedLoad, 157.5, accuracy: 0.01)
    }

    func testFatigueAdjustment_AdjustedLoad_ZeroOriginal() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        let adjustedLoad = adjustment.adjustedLoad(0.0)

        XCTAssertEqual(adjustedLoad, 0.0, accuracy: 0.01)
    }

    // MARK: - Round To Nearest 5 Logic Tests

    func testFatigueAdjustment_RoundToNearest5_ExactMultiple() {
        XCTAssertEqual(roundToNearest5(100.0), 100.0)
        XCTAssertEqual(roundToNearest5(105.0), 105.0)
        XCTAssertEqual(roundToNearest5(95.0), 95.0)
    }

    func testFatigueAdjustment_RoundToNearest5_RoundsDown() {
        XCTAssertEqual(roundToNearest5(102.0), 100.0)
        XCTAssertEqual(roundToNearest5(101.0), 100.0)
        XCTAssertEqual(roundToNearest5(97.0), 95.0)
    }

    func testFatigueAdjustment_RoundToNearest5_RoundsUp() {
        XCTAssertEqual(roundToNearest5(103.0), 105.0)
        XCTAssertEqual(roundToNearest5(108.0), 110.0)
        XCTAssertEqual(roundToNearest5(98.0), 100.0)
    }

    func testFatigueAdjustment_RoundToNearest5_Midpoint() {
        // 2.5 is the midpoint - should round up
        XCTAssertEqual(roundToNearest5(102.5), 105.0)
        XCTAssertEqual(roundToNearest5(97.5), 100.0)
    }

    func testFatigueAdjustment_RoundToNearest5_SmallValues() {
        XCTAssertEqual(roundToNearest5(3.0), 5.0)
        XCTAssertEqual(roundToNearest5(2.0), 0.0)
        XCTAssertEqual(roundToNearest5(7.0), 5.0)
        XCTAssertEqual(roundToNearest5(8.0), 10.0)
    }

    func testFatigueAdjustment_RoundToNearest5_Zero() {
        XCTAssertEqual(roundToNearest5(0.0), 0.0)
    }

    func testFatigueAdjustment_RoundToNearest5_LargeValues() {
        XCTAssertEqual(roundToNearest5(1003.0), 1005.0)
        XCTAssertEqual(roundToNearest5(997.0), 995.0)
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

    func testFatigueAdjustment_LoadReductionExceedsVolume_ForCritical() {
        let fatigue = createFatigueAccumulation(band: .critical)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Critical: 50% load, 40% volume - load reduction is higher
        XCTAssertGreaterThan(adjustment.loadReductionPct, adjustment.volumeReductionPct)
    }

    func testFatigueAdjustment_LoadReductionExceedsVolume_ForHigh() {
        let fatigue = createFatigueAccumulation(band: .high)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // High: 30% load, 25% volume - load reduction is higher
        XCTAssertGreaterThan(adjustment.loadReductionPct, adjustment.volumeReductionPct)
    }

    func testFatigueAdjustment_LoadReductionEqualsVolume_ForModerate() {
        let fatigue = createFatigueAccumulation(band: .moderate)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Moderate: 10% load, 10% volume - equal
        XCTAssertEqual(adjustment.loadReductionPct, adjustment.volumeReductionPct)
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

    func testFatigueAdjustment_ReductionsAreDivisibleBy5() {
        // All reduction percentages should be divisible by 5 for clean display
        for band in [FatigueBand.moderate, .high, .critical] {
            let fatigue = createFatigueAccumulation(band: band)
            let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

            XCTAssertEqual(adjustment.loadReductionPercent % 5, 0,
                          "Load reduction \(adjustment.loadReductionPercent)% should be divisible by 5")
            XCTAssertEqual(adjustment.volumeReductionPercent % 5, 0,
                          "Volume reduction \(adjustment.volumeReductionPercent)% should be divisible by 5")
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

    // MARK: - Integration-like Tests

    func testFatigueAdjustment_TypicalWorkoutScenario() {
        // Simulate a typical workout adjustment scenario
        let fatigue = createFatigueAccumulation(band: .high, deloadRecommended: false)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Original workout: 4 sets of 5 reps at 200 lbs
        let originalLoad = 200.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // Should reduce by 30%
        XCTAssertEqual(adjustedLoad, 140.0, accuracy: 0.01)

        // Adjustment should be active but not a deload week
        XCTAssertTrue(adjustment.isActive)
        XCTAssertFalse(adjustment.isDeloadWeek)
    }

    func testFatigueAdjustment_DeloadWeekScenario() {
        // Simulate a deload week scenario
        let fatigue = createFatigueAccumulation(band: .critical, deloadRecommended: true)
        let adjustment = FatigueAdjustment.from(fatigue: fatigue)!

        // Original workout: 200 lbs
        let originalLoad = 200.0
        let adjustedLoad = adjustment.adjustedLoad(originalLoad)

        // Should reduce by 50%
        XCTAssertEqual(adjustedLoad, 100.0, accuracy: 0.01)

        // Should be both active and a deload week
        XCTAssertTrue(adjustment.isActive)
        XCTAssertTrue(adjustment.isDeloadWeek)
        XCTAssertTrue(adjustment.isDeload)
    }

    // MARK: - Helper Methods

    /// Round a value to the nearest 5
    private func roundToNearest5(_ value: Double) -> Double {
        return (value / 5.0).rounded() * 5.0
    }
}
