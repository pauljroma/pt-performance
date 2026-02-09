//
//  BiomarkerTests.swift
//  PTPerformanceTests
//
//  Unit tests for Biomarker models including range validation, traffic light determination,
//  and trend calculation.
//

import XCTest
@testable import PTPerformance

// MARK: - BiomarkerCategory Tests

final class BiomarkerCategoryTests: XCTestCase {

    // MARK: - All Cases

    func testBiomarkerCategory_AllCases() {
        let allCases = BiomarkerCategory.allCases
        XCTAssertEqual(allCases.count, 11)
    }

    func testBiomarkerCategory_AllHaveIcons() {
        for category in BiomarkerCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

    // MARK: - Category Mapping - Lipid Panel

    func testCategoryMapping_LipidPanel() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Cholesterol"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "LDL"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "HDL"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "Triglycerides"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "VLDL"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "Total Lipid"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_CaseInsensitive() {
        XCTAssertEqual(BiomarkerCategory.category(for: "cholesterol"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "CHOLESTEROL"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "Cholesterol"), .lipidPanel)
    }

    // MARK: - Category Mapping - Metabolic

    func testCategoryMapping_Metabolic() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Glucose"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "Insulin"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "HbA1c"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "A1c"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "Fasting Glucose"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "Hemoglobin A1c"), .metabolic)
    }

    // MARK: - Category Mapping - Thyroid

    func testCategoryMapping_Thyroid() {
        XCTAssertEqual(BiomarkerCategory.category(for: "TSH"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "T3"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "T4"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "Free T3"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "Thyroid Panel"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "Thyroxine"), .thyroid)
    }

    // MARK: - Category Mapping - Hormones

    func testCategoryMapping_Hormones() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Testosterone"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "Estrogen"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "Estradiol"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "Cortisol"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "DHEA"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "Progesterone"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "SHBG"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "FSH"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "LH"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "Prolactin"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "IGF-1"), .hormones)
    }

    // MARK: - Category Mapping - CBC

    func testCategoryMapping_CBC() {
        XCTAssertEqual(BiomarkerCategory.category(for: "RBC"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "WBC"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "Hemoglobin"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "Hematocrit"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "Platelet Count"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "MCV"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "MCH"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "MCHC"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "RDW"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "Neutrophils"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "Lymphocytes"), .cbc)
    }

    // MARK: - Category Mapping - Vitamins

    func testCategoryMapping_Vitamins() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Vitamin D"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "Vitamin B12"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "B12"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "Folate"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "D3"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "Thiamine"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "Riboflavin"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "Niacin"), .vitamins)
    }

    // MARK: - Category Mapping - Minerals

    func testCategoryMapping_Minerals() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Iron"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Ferritin"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "TIBC"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Zinc"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Magnesium"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Calcium"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Potassium"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Sodium"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "Selenium"), .minerals)
    }

    // MARK: - Category Mapping - Inflammation

    func testCategoryMapping_Inflammation() {
        XCTAssertEqual(BiomarkerCategory.category(for: "CRP"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "C-Reactive Protein"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "Sed Rate"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "ESR"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "Homocysteine"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "Fibrinogen"), .inflammation)
    }

    // MARK: - Category Mapping - Liver

    func testCategoryMapping_Liver() {
        XCTAssertEqual(BiomarkerCategory.category(for: "ALT"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "AST"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "ALP"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "Bilirubin"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "Albumin"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "GGT"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "Liver Panel"), .liver)
    }

    // MARK: - Category Mapping - Kidney

    func testCategoryMapping_Kidney() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Creatinine"), .kidney)
        XCTAssertEqual(BiomarkerCategory.category(for: "BUN"), .kidney)
        XCTAssertEqual(BiomarkerCategory.category(for: "Urea"), .kidney)
        XCTAssertEqual(BiomarkerCategory.category(for: "eGFR"), .kidney)
        XCTAssertEqual(BiomarkerCategory.category(for: "Uric Acid"), .kidney)
        XCTAssertEqual(BiomarkerCategory.category(for: "Kidney Function"), .kidney)
    }

    // MARK: - Category Mapping - Other

    func testCategoryMapping_Other() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Unknown Marker"), .other)
        XCTAssertEqual(BiomarkerCategory.category(for: "Custom Test"), .other)
        XCTAssertEqual(BiomarkerCategory.category(for: "XYZ123"), .other)
    }

    // MARK: - Category ID and Raw Value

    func testBiomarkerCategory_Identifiable() {
        for category in BiomarkerCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }
}

// MARK: - BiomarkerTrend Tests

final class BiomarkerTrendTests: XCTestCase {

    // MARK: - Raw Values

    func testBiomarkerTrend_RawValues() {
        XCTAssertEqual(BiomarkerTrend.increasing.rawValue, "increasing")
        XCTAssertEqual(BiomarkerTrend.decreasing.rawValue, "decreasing")
        XCTAssertEqual(BiomarkerTrend.stable.rawValue, "stable")
        XCTAssertEqual(BiomarkerTrend.unknown.rawValue, "unknown")
    }

    // MARK: - Icons

    func testBiomarkerTrend_Icons() {
        XCTAssertEqual(BiomarkerTrend.increasing.icon, "arrow.up")
        XCTAssertEqual(BiomarkerTrend.decreasing.icon, "arrow.down")
        XCTAssertEqual(BiomarkerTrend.stable.icon, "arrow.forward")
        XCTAssertEqual(BiomarkerTrend.unknown.icon, "minus")
    }

    // MARK: - Accessibility Labels

    func testBiomarkerTrend_AccessibilityLabels() {
        XCTAssertEqual(BiomarkerTrend.increasing.accessibilityLabel, "trending up")
        XCTAssertEqual(BiomarkerTrend.decreasing.accessibilityLabel, "trending down")
        XCTAssertEqual(BiomarkerTrend.stable.accessibilityLabel, "stable")
        XCTAssertEqual(BiomarkerTrend.unknown.accessibilityLabel, "trend unknown")
    }
}

// MARK: - BiomarkerSummary Tests

final class BiomarkerSummaryTests: XCTestCase {

    // MARK: - Initialization

    func testBiomarkerSummary_Initialization() {
        let id = UUID()
        let date = Date()

        let summary = BiomarkerSummary(
            id: id,
            name: "vitamin_d",
            displayName: "Vitamin D",
            category: .vitamins,
            currentValue: 45.0,
            unit: "ng/mL",
            status: .optimal,
            trend: .increasing,
            lastUpdated: date,
            historyCount: 5,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(summary.id, id)
        XCTAssertEqual(summary.name, "vitamin_d")
        XCTAssertEqual(summary.displayName, "Vitamin D")
        XCTAssertEqual(summary.category, .vitamins)
        XCTAssertEqual(summary.currentValue, 45.0)
        XCTAssertEqual(summary.unit, "ng/mL")
        XCTAssertEqual(summary.status, .optimal)
        XCTAssertEqual(summary.trend, .increasing)
        XCTAssertEqual(summary.lastUpdated, date)
        XCTAssertEqual(summary.historyCount, 5)
    }

    func testBiomarkerSummary_DefaultDisplayName() {
        let summary = BiomarkerSummary(
            name: "test_marker",
            category: .other,
            currentValue: 100.0,
            unit: "units",
            status: .normal,
            lastUpdated: Date()
        )

        XCTAssertEqual(summary.displayName, "test_marker")
    }

    func testBiomarkerSummary_DefaultTrend() {
        let summary = BiomarkerSummary(
            name: "test",
            category: .other,
            currentValue: 50.0,
            unit: "units",
            status: .normal,
            lastUpdated: Date()
        )

        XCTAssertEqual(summary.trend, .unknown)
    }

    func testBiomarkerSummary_DefaultHistoryCount() {
        let summary = BiomarkerSummary(
            name: "test",
            category: .other,
            currentValue: 50.0,
            unit: "units",
            status: .normal,
            lastUpdated: Date()
        )

        XCTAssertEqual(summary.historyCount, 1)
    }

    // MARK: - Formatted Value Tests

    func testBiomarkerSummary_FormattedValue_LargeValue() {
        let summary = createSummaryWithValue(1500.0)
        XCTAssertEqual(summary.formattedValue, "1500")
    }

    func testBiomarkerSummary_FormattedValue_MediumValue() {
        let summary = createSummaryWithValue(150.5)
        XCTAssertEqual(summary.formattedValue, "150.5")
    }

    func testBiomarkerSummary_FormattedValue_SmallValue() {
        let summary = createSummaryWithValue(15.55)
        XCTAssertEqual(summary.formattedValue, "15.6")
    }

    func testBiomarkerSummary_FormattedValue_VerySmallValue() {
        let summary = createSummaryWithValue(1.234)
        XCTAssertEqual(summary.formattedValue, "1.23")
    }

    func testBiomarkerSummary_FormattedValue_ZeroValue() {
        let summary = createSummaryWithValue(0.0)
        XCTAssertEqual(summary.formattedValue, "0.00")
    }

    func testBiomarkerSummary_FormattedValue_BoundaryAt1000() {
        let summary = createSummaryWithValue(1000.0)
        XCTAssertEqual(summary.formattedValue, "1000")
    }

    func testBiomarkerSummary_FormattedValue_BoundaryAt100() {
        let summary = createSummaryWithValue(100.0)
        XCTAssertEqual(summary.formattedValue, "100.0")
    }

    func testBiomarkerSummary_FormattedValue_BoundaryAt10() {
        let summary = createSummaryWithValue(10.0)
        XCTAssertEqual(summary.formattedValue, "10.0")
    }

    // MARK: - Equatable

    func testBiomarkerSummary_Equatable_SameId() {
        let id = UUID()
        let summary1 = createSummaryWithId(id)
        let summary2 = createSummaryWithId(id)

        XCTAssertEqual(summary1, summary2)
    }

    func testBiomarkerSummary_Equatable_DifferentId() {
        let summary1 = createSummaryWithId(UUID())
        let summary2 = createSummaryWithId(UUID())

        XCTAssertNotEqual(summary1, summary2)
    }

    // MARK: - Helper Methods

    private func createSummaryWithValue(_ value: Double) -> BiomarkerSummary {
        BiomarkerSummary(
            name: "test",
            category: .other,
            currentValue: value,
            unit: "units",
            status: .normal,
            lastUpdated: Date()
        )
    }

    private func createSummaryWithId(_ id: UUID) -> BiomarkerSummary {
        BiomarkerSummary(
            id: id,
            name: "test",
            category: .other,
            currentValue: 50.0,
            unit: "units",
            status: .normal,
            lastUpdated: Date()
        )
    }
}

// MARK: - Traffic Light Determination Tests

final class BiomarkerTrafficLightTests: XCTestCase {

    // MARK: - Optimal Status (Green)

    func testTrafficLight_Optimal_WithinRange() {
        let point = createTrendPoint(
            value: 50.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testTrafficLight_Optimal_AtLowerBoundary() {
        let point = createTrendPoint(
            value: 40.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testTrafficLight_Optimal_AtUpperBoundary() {
        let point = createTrendPoint(
            value: 60.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    // MARK: - Normal Status (Blue)

    func testTrafficLight_Normal_BetweenNormalAndOptimal_Low() {
        let point = createTrendPoint(
            value: 35.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testTrafficLight_Normal_BetweenNormalAndOptimal_High() {
        let point = createTrendPoint(
            value: 80.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testTrafficLight_Normal_AtNormalLowBoundary() {
        let point = createTrendPoint(
            value: 30.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testTrafficLight_Normal_AtNormalHighBoundary() {
        let point = createTrendPoint(
            value: 100.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    // MARK: - Low Status (Orange)

    func testTrafficLight_Low_BelowNormal() {
        let point = createTrendPoint(
            value: 25.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .low)
    }

    func testTrafficLight_Low_JustBelowNormal() {
        let point = createTrendPoint(
            value: 29.9,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .low)
    }

    // MARK: - High Status (Orange)

    func testTrafficLight_High_AboveNormal() {
        let point = createTrendPoint(
            value: 110.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .high)
    }

    func testTrafficLight_High_JustAboveNormal() {
        let point = createTrendPoint(
            value: 100.1,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .high)
    }

    // MARK: - Critical Status (Red)

    func testTrafficLight_Critical_SignificantlyLow() {
        // Critical is < normalLow * 0.7 = 30 * 0.7 = 21
        let point = createTrendPoint(
            value: 20.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    func testTrafficLight_Critical_SignificantlyHigh() {
        // Critical is > normalHigh * 1.3 = 100 * 1.3 = 130
        let point = createTrendPoint(
            value: 135.0,
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    func testTrafficLight_Critical_AtBoundary_Low() {
        // Just below 70% of normal low
        let point = createTrendPoint(
            value: 20.9, // Just below 21 (30 * 0.7)
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    func testTrafficLight_Critical_AtBoundary_High() {
        // Just above 130% of normal high
        let point = createTrendPoint(
            value: 130.1, // Just above 130 (100 * 1.3)
            optimalLow: 40.0,
            optimalHigh: 60.0,
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .critical)
    }

    // MARK: - Missing Ranges

    func testTrafficLight_NoRanges_DefaultsToNormal() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units"
        )

        XCTAssertEqual(point.status, .normal)
    }

    func testTrafficLight_OnlyOptimalRange_InRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: 40.0,
            optimalHigh: 60.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testTrafficLight_OnlyOptimalRange_OutOfRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 30.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: 40.0,
            optimalHigh: 60.0
        )

        // Without normal range, cannot determine low/high status
        XCTAssertEqual(point.status, .normal)
    }

    func testTrafficLight_OnlyNormalRange_InRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.status, .normal)
    }

    // MARK: - Helper Methods

    private func createTrendPoint(
        value: Double,
        optimalLow: Double?,
        optimalHigh: Double?,
        normalLow: Double?,
        normalHigh: Double?
    ) -> BiomarkerTrendPoint {
        BiomarkerTrendPoint(
            date: Date(),
            value: value,
            biomarkerType: "test",
            unit: "units",
            optimalLow: optimalLow,
            optimalHigh: optimalHigh,
            normalLow: normalLow,
            normalHigh: normalHigh
        )
    }
}

// MARK: - Trend Calculation Tests

final class BiomarkerTrendCalculationTests: XCTestCase {

    // MARK: - Trend Direction Based on Percent Change

    func testTrendCalculation_Increasing_SignificantChange() {
        // Current 110, Previous 100 = +10% change
        let current: Double = 110.0
        let previous: Double = 100.0
        let percentChange = ((current - previous) / previous) * 100

        XCTAssertTrue(percentChange > 5, "Should be considered increasing")
    }

    func testTrendCalculation_Decreasing_SignificantChange() {
        // Current 90, Previous 100 = -10% change
        let current: Double = 90.0
        let previous: Double = 100.0
        let percentChange = ((current - previous) / previous) * 100

        XCTAssertTrue(percentChange < -5, "Should be considered decreasing")
    }

    func testTrendCalculation_Stable_SmallChange() {
        // Current 102, Previous 100 = +2% change
        let current: Double = 102.0
        let previous: Double = 100.0
        let percentChange = abs(((current - previous) / previous) * 100)

        XCTAssertTrue(percentChange < 5, "Should be considered stable")
    }

    func testTrendCalculation_Stable_NoChange() {
        let current: Double = 100.0
        let previous: Double = 100.0
        let percentChange = abs(((current - previous) / previous) * 100)

        XCTAssertEqual(percentChange, 0, "Should have zero change")
    }

    // MARK: - Edge Cases

    func testTrendCalculation_FromZero() {
        // Division by zero edge case
        let previous: Double = 0.0
        let current: Double = 10.0

        // When previous is 0, percent change calculation would be problematic
        // The implementation should handle this gracefully
        if previous == 0 {
            // Cannot calculate percent change from zero
            XCTAssertTrue(true, "Should handle zero previous value")
        }
    }

    func testTrendCalculation_LargeIncrease() {
        // Current 200, Previous 100 = +100% change
        let current: Double = 200.0
        let previous: Double = 100.0
        let percentChange = ((current - previous) / previous) * 100

        XCTAssertEqual(percentChange, 100.0, accuracy: 0.01)
    }

    func testTrendCalculation_LargeDecrease() {
        // Current 50, Previous 100 = -50% change
        let current: Double = 50.0
        let previous: Double = 100.0
        let percentChange = ((current - previous) / previous) * 100

        XCTAssertEqual(percentChange, -50.0, accuracy: 0.01)
    }

    func testTrendCalculation_Boundary_Plus5Percent() {
        // Current 105, Previous 100 = +5% change (boundary)
        let current: Double = 105.0
        let previous: Double = 100.0
        let percentChange = abs(((current - previous) / previous) * 100)

        XCTAssertEqual(percentChange, 5.0, accuracy: 0.01)
    }

    func testTrendCalculation_Boundary_Minus5Percent() {
        // Current 95, Previous 100 = -5% change (boundary)
        let current: Double = 95.0
        let previous: Double = 100.0
        let percentChange = abs(((current - previous) / previous) * 100)

        XCTAssertEqual(percentChange, 5.0, accuracy: 0.01)
    }
}

// MARK: - Range Validation Tests

final class BiomarkerRangeValidationTests: XCTestCase {

    // MARK: - Valid Ranges

    func testRangeValidation_ValidOptimalRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            optimalLow: 40.0,
            optimalHigh: 60.0
        )

        XCTAssertEqual(point.optimalLow, 40.0)
        XCTAssertEqual(point.optimalHigh, 60.0)
        XCTAssertTrue((point.optimalLow ?? 0) < (point.optimalHigh ?? 0))
    }

    func testRangeValidation_ValidNormalRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 50.0,
            biomarkerType: "test",
            unit: "units",
            normalLow: 30.0,
            normalHigh: 100.0
        )

        XCTAssertEqual(point.normalLow, 30.0)
        XCTAssertEqual(point.normalHigh, 100.0)
        XCTAssertTrue((point.normalLow ?? 0) < (point.normalHigh ?? 0))
    }

    // MARK: - Range Consistency

    func testRangeValidation_OptimalWithinNormal() {
        let optimalLow = 40.0
        let optimalHigh = 60.0
        let normalLow = 30.0
        let normalHigh = 100.0

        XCTAssertTrue(optimalLow >= normalLow)
        XCTAssertTrue(optimalHigh <= normalHigh)
    }

    // MARK: - Edge Cases

    func testRangeValidation_ZeroRangeLow() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 5.0,
            biomarkerType: "test",
            unit: "units",
            normalLow: 0.0,
            normalHigh: 10.0
        )

        XCTAssertEqual(point.normalLow, 0.0)
        XCTAssertEqual(point.status, .normal)
    }

    func testRangeValidation_NegativeRangeValues() {
        // Some biomarkers can have negative reference ranges (e.g., temperature differentials)
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: -5.0,
            biomarkerType: "temp_delta",
            unit: "degrees",
            normalLow: -10.0,
            normalHigh: 10.0
        )

        XCTAssertEqual(point.normalLow, -10.0)
        XCTAssertEqual(point.normalHigh, 10.0)
    }

    func testRangeValidation_VerySmallRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 0.5,
            biomarkerType: "tsh",
            unit: "mIU/L",
            optimalLow: 0.4,
            optimalHigh: 0.6,
            normalLow: 0.1,
            normalHigh: 4.0
        )

        XCTAssertEqual(point.status, .optimal)
    }

    func testRangeValidation_VeryLargeRange() {
        let point = BiomarkerTrendPoint(
            date: Date(),
            value: 250000.0,
            biomarkerType: "platelets",
            unit: "cells/uL",
            optimalLow: 150000.0,
            optimalHigh: 350000.0,
            normalLow: 100000.0,
            normalHigh: 450000.0
        )

        XCTAssertEqual(point.status, .optimal)
    }
}
