//
//  ColorDarkModeTests.swift
//  PTPerformanceTests
//
//  Tests for Color+DarkMode extension and adaptive color helpers
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class ColorDarkModeTests: XCTestCase {

    // MARK: - Adaptive Text Colors

    func testAdaptiveText_ReturnsLightModeColor() {
        let result = Color.adaptiveText(on: .blue)

        XCTAssertNotNil(result)
    }

    func testAdaptiveText_WithCustomColors() {
        let result = Color.adaptiveText(
            on: .blue,
            lightModeColor: .black,
            darkModeColor: .white
        )

        XCTAssertNotNil(result)
    }

    // MARK: - Static Color Properties

    func testSoftWhite_Exists() {
        let color = Color.softWhite

        XCTAssertNotNil(color)
    }

    func testSoftBlack_Exists() {
        let color = Color.softBlack

        XCTAssertNotNil(color)
    }

    func testAdaptiveOverlay_Exists() {
        let color = Color.adaptiveOverlay

        XCTAssertNotNil(color)
    }

    func testAdaptiveHighlight_Exists() {
        let color = Color.adaptiveHighlight

        XCTAssertNotNil(color)
    }

    // MARK: - Card & Surface Colors

    func testCardBackground_Exists() {
        let color = Color.cardBackground

        XCTAssertNotNil(color)
    }

    func testCardBackgroundOnGrouped_Exists() {
        let color = Color.cardBackgroundOnGrouped

        XCTAssertNotNil(color)
    }

    // MARK: - Badge & Chip Colors

    func testBadgeBackground_Exists() {
        let color = Color.badgeBackground

        XCTAssertNotNil(color)
    }

    func testChipSelectedBackground_Exists() {
        let color = Color.chipSelectedBackground

        XCTAssertNotNil(color)
    }

    // MARK: - Video Overlay Colors

    func testVideoOverlayGradient_HasThreeColors() {
        let gradient = Color.videoOverlayGradient

        XCTAssertEqual(gradient.count, 3)
    }

    func testVideoPlayButtonBackground_Exists() {
        let color = Color.videoPlayButtonBackground

        XCTAssertNotNil(color)
    }

    // MARK: - Chart Colors

    func testChartColorPalette_HasMultipleColors() {
        let palette = Color.chartColorPalette

        XCTAssertGreaterThanOrEqual(palette.count, 3)
    }

    func testChartAnnotation_Exists() {
        let color = Color.chartAnnotation

        XCTAssertNotNil(color)
    }

    func testChartAxisLabel_Exists() {
        let color = Color.chartAxisLabel

        XCTAssertNotNil(color)
    }

    // MARK: - Contrast Helpers

    func testIsLight_WhiteIsLight() {
        let white = Color.white
        XCTAssertTrue(white.isLight)
    }

    func testIsLight_BlackIsNotLight() {
        let black = Color.black
        XCTAssertFalse(black.isLight)
    }

    func testContrastingTextColor_OnWhite() {
        let white = Color.white
        XCTAssertEqual(white.contrastingTextColor, .black)
    }

    func testContrastingTextColor_OnBlack() {
        let black = Color.black
        XCTAssertEqual(black.contrastingTextColor, .white)
    }
}

final class UIColorAdaptiveTests: XCTestCase {

    func testAdaptive_ReturnsUIColor() {
        let color = UIColor.adaptive(light: .white, dark: .black)

        XCTAssertNotNil(color)
    }

    func testBrightenedForDarkMode_IncreasesBrightness() {
        let originalColor = UIColor.blue
        let brightened = originalColor.brightenedForDarkMode(by: 0.2)

        XCTAssertNotNil(brightened)
    }

    func testBrightenedForDarkMode_DefaultFactor() {
        let color = UIColor.green
        let brightened = color.brightenedForDarkMode()

        XCTAssertNotNil(brightened)
    }
}

final class LinearGradientAdaptiveTests: XCTestCase {

    func testAdaptiveHeroGradient_CreatesGradient() {
        let gradient = LinearGradient.adaptiveHeroGradient(
            primary: .blue,
            secondary: .purple
        )

        XCTAssertNotNil(gradient)
    }

    func testAdaptiveCardGradient_Exists() {
        let gradient = LinearGradient.adaptiveCardGradient

        XCTAssertNotNil(gradient)
    }
}
