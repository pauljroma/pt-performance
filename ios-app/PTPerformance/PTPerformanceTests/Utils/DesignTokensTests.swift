//
//  DesignTokensTests.swift
//  PTPerformanceTests
//
//  Tests for DesignTokens constants and semantic colors
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class DesignTokensConstantsTests: XCTestCase {

    // MARK: - Corner Radius Tests

    func testCornerRadius_SmallValue() {
        XCTAssertEqual(DesignTokens.cornerRadiusSmall, 8)
    }

    func testCornerRadius_MediumValue() {
        XCTAssertEqual(DesignTokens.cornerRadiusMedium, 12)
    }

    func testCornerRadius_LargeValue() {
        XCTAssertEqual(DesignTokens.cornerRadiusLarge, 16)
    }

    func testCornerRadius_XLargeValue() {
        XCTAssertEqual(DesignTokens.cornerRadiusXLarge, 20)
    }

    func testCornerRadius_Hierarchy() {
        XCTAssertLessThan(DesignTokens.cornerRadiusSmall, DesignTokens.cornerRadiusMedium)
        XCTAssertLessThan(DesignTokens.cornerRadiusMedium, DesignTokens.cornerRadiusLarge)
        XCTAssertLessThan(DesignTokens.cornerRadiusLarge, DesignTokens.cornerRadiusXLarge)
    }

    // MARK: - Spacing Tests

    func testSpacing_XSmallValue() {
        XCTAssertEqual(DesignTokens.spacingXSmall, 4)
    }

    func testSpacing_SmallValue() {
        XCTAssertEqual(DesignTokens.spacingSmall, 8)
    }

    func testSpacing_MediumValue() {
        XCTAssertEqual(DesignTokens.spacingMedium, 12)
    }

    func testSpacing_LargeValue() {
        XCTAssertEqual(DesignTokens.spacingLarge, 16)
    }

    func testSpacing_XLargeValue() {
        XCTAssertEqual(DesignTokens.spacingXLarge, 24)
    }

    func testSpacing_XXLargeValue() {
        XCTAssertEqual(DesignTokens.spacingXXLarge, 32)
    }

    func testSpacing_Hierarchy() {
        XCTAssertLessThan(DesignTokens.spacingXSmall, DesignTokens.spacingSmall)
        XCTAssertLessThan(DesignTokens.spacingSmall, DesignTokens.spacingMedium)
        XCTAssertLessThan(DesignTokens.spacingMedium, DesignTokens.spacingLarge)
        XCTAssertLessThan(DesignTokens.spacingLarge, DesignTokens.spacingXLarge)
        XCTAssertLessThan(DesignTokens.spacingXLarge, DesignTokens.spacingXXLarge)
    }

    // MARK: - Icon Size Tests

    func testIconSize_SmallValue() {
        XCTAssertEqual(DesignTokens.iconSizeSmall, 16)
    }

    func testIconSize_MediumValue() {
        XCTAssertEqual(DesignTokens.iconSizeMedium, 24)
    }

    func testIconSize_LargeValue() {
        XCTAssertEqual(DesignTokens.iconSizeLarge, 32)
    }

    func testIconSize_XLargeValue() {
        XCTAssertEqual(DesignTokens.iconSizeXLarge, 48)
    }

    func testIconSize_XXLargeValue() {
        XCTAssertEqual(DesignTokens.iconSizeXXLarge, 64)
    }

    func testIconSize_Hierarchy() {
        XCTAssertLessThan(DesignTokens.iconSizeSmall, DesignTokens.iconSizeMedium)
        XCTAssertLessThan(DesignTokens.iconSizeMedium, DesignTokens.iconSizeLarge)
        XCTAssertLessThan(DesignTokens.iconSizeLarge, DesignTokens.iconSizeXLarge)
        XCTAssertLessThan(DesignTokens.iconSizeXLarge, DesignTokens.iconSizeXXLarge)
    }

    // MARK: - Animation Duration Tests

    func testAnimationDuration_FastValue() {
        XCTAssertEqual(DesignTokens.animationDurationFast, 0.15)
    }

    func testAnimationDuration_NormalValue() {
        XCTAssertEqual(DesignTokens.animationDurationNormal, 0.3)
    }

    func testAnimationDuration_SlowValue() {
        XCTAssertEqual(DesignTokens.animationDurationSlow, 0.5)
    }

    func testAnimationDuration_Hierarchy() {
        XCTAssertLessThan(DesignTokens.animationDurationFast, DesignTokens.animationDurationNormal)
        XCTAssertLessThan(DesignTokens.animationDurationNormal, DesignTokens.animationDurationSlow)
    }
}

final class DesignTokensSemanticColorsTests: XCTestCase {

    // MARK: - Background Colors

    func testBackgroundPrimary_Exists() {
        let color = DesignTokens.backgroundPrimary
        XCTAssertNotNil(color)
    }

    func testBackgroundSecondary_Exists() {
        let color = DesignTokens.backgroundSecondary
        XCTAssertNotNil(color)
    }

    func testBackgroundTertiary_Exists() {
        let color = DesignTokens.backgroundTertiary
        XCTAssertNotNil(color)
    }

    func testBackgroundGrouped_Exists() {
        let color = DesignTokens.backgroundGrouped
        XCTAssertNotNil(color)
    }

    func testSurfaceElevated_Exists() {
        let color = DesignTokens.surfaceElevated
        XCTAssertNotNil(color)
    }

    // MARK: - Text Colors

    func testTextPrimary_Exists() {
        let color = DesignTokens.textPrimary
        XCTAssertNotNil(color)
    }

    func testTextSecondary_Exists() {
        let color = DesignTokens.textSecondary
        XCTAssertNotNil(color)
    }

    func testTextTertiary_Exists() {
        let color = DesignTokens.textTertiary
        XCTAssertNotNil(color)
    }

    func testTextPlaceholder_Exists() {
        let color = DesignTokens.textPlaceholder
        XCTAssertNotNil(color)
    }

    // MARK: - Separator Colors

    func testSeparator_Exists() {
        let color = DesignTokens.separator
        XCTAssertNotNil(color)
    }

    func testSeparatorOpaque_Exists() {
        let color = DesignTokens.separatorOpaque
        XCTAssertNotNil(color)
    }

    // MARK: - Fill Colors

    func testFillPrimary_Exists() {
        let color = DesignTokens.fillPrimary
        XCTAssertNotNil(color)
    }

    func testFillSecondary_Exists() {
        let color = DesignTokens.fillSecondary
        XCTAssertNotNil(color)
    }

    func testFillTertiary_Exists() {
        let color = DesignTokens.fillTertiary
        XCTAssertNotNil(color)
    }

    func testFillQuaternary_Exists() {
        let color = DesignTokens.fillQuaternary
        XCTAssertNotNil(color)
    }

    // MARK: - Status Colors

    func testStatusSuccess_Exists() {
        let color = DesignTokens.statusSuccess
        XCTAssertNotNil(color)
    }

    func testStatusWarning_Exists() {
        let color = DesignTokens.statusWarning
        XCTAssertNotNil(color)
    }

    func testStatusError_Exists() {
        let color = DesignTokens.statusError
        XCTAssertNotNil(color)
    }

    func testStatusInfo_Exists() {
        let color = DesignTokens.statusInfo
        XCTAssertNotNil(color)
    }

    // MARK: - Chart Colors

    func testChartPrimary_Exists() {
        let color = DesignTokens.chartPrimary
        XCTAssertNotNil(color)
    }

    func testChartSecondary_Exists() {
        let color = DesignTokens.chartSecondary
        XCTAssertNotNil(color)
    }

    func testChartTertiary_Exists() {
        let color = DesignTokens.chartTertiary
        XCTAssertNotNil(color)
    }

    func testChartFill_Exists() {
        let color = DesignTokens.chartFill
        XCTAssertNotNil(color)
    }

    func testChartGrid_Exists() {
        let color = DesignTokens.chartGrid
        XCTAssertNotNil(color)
    }

    // MARK: - Button Colors

    func testButtonTextOnAccent_IsWhite() {
        XCTAssertEqual(DesignTokens.buttonTextOnAccent, Color.white)
    }

    func testButtonTextSecondary_Exists() {
        let color = DesignTokens.buttonTextSecondary
        XCTAssertNotNil(color)
    }

    // MARK: - Shadow Colors

    func testShadowColor_Exists() {
        let color = DesignTokens.shadowColor
        XCTAssertNotNil(color)
    }

    func testShadowSubtle_Exists() {
        let color = DesignTokens.shadowSubtle
        XCTAssertNotNil(color)
    }
}
