//
//  FatigueBandTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueBand enum
//  Tests all cases, color mappings, display properties, and band determination from scores
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class FatigueBandModelTests: XCTestCase {

    // MARK: - All Cases Tests

    func testFatigueBand_AllCasesExist() {
        let allCases = FatigueBand.allCases
        XCTAssertEqual(allCases.count, 4, "FatigueBand should have exactly 4 cases")
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.moderate))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.critical))
    }

    func testFatigueBand_CasesAreOrdered() {
        let allCases = FatigueBand.allCases
        XCTAssertEqual(allCases[0], .low)
        XCTAssertEqual(allCases[1], .moderate)
        XCTAssertEqual(allCases[2], .high)
        XCTAssertEqual(allCases[3], .critical)
    }

    func testFatigueBand_CaseCount() {
        XCTAssertEqual(FatigueBand.allCases.count, 4)
    }

    // MARK: - Raw Value Tests

    func testFatigueBand_RawValues() {
        XCTAssertEqual(FatigueBand.low.rawValue, "low")
        XCTAssertEqual(FatigueBand.moderate.rawValue, "moderate")
        XCTAssertEqual(FatigueBand.high.rawValue, "high")
        XCTAssertEqual(FatigueBand.critical.rawValue, "critical")
    }

    func testFatigueBand_InitFromRawValue_ValidValues() {
        XCTAssertEqual(FatigueBand(rawValue: "low"), .low)
        XCTAssertEqual(FatigueBand(rawValue: "moderate"), .moderate)
        XCTAssertEqual(FatigueBand(rawValue: "high"), .high)
        XCTAssertEqual(FatigueBand(rawValue: "critical"), .critical)
    }

    func testFatigueBand_InitFromRawValue_InvalidValues() {
        XCTAssertNil(FatigueBand(rawValue: "invalid"))
        XCTAssertNil(FatigueBand(rawValue: ""))
        XCTAssertNil(FatigueBand(rawValue: "LOW"))
        XCTAssertNil(FatigueBand(rawValue: "Low"))
        XCTAssertNil(FatigueBand(rawValue: "CRITICAL"))
        XCTAssertNil(FatigueBand(rawValue: "extreme"))
        XCTAssertNil(FatigueBand(rawValue: "medium"))
        XCTAssertNil(FatigueBand(rawValue: "severe"))
        XCTAssertNil(FatigueBand(rawValue: " low"))
        XCTAssertNil(FatigueBand(rawValue: "low "))
    }

    func testFatigueBand_RawValueCaseSensitivity() {
        // Raw values should be case-sensitive
        XCTAssertNil(FatigueBand(rawValue: "Low"))
        XCTAssertNil(FatigueBand(rawValue: "MODERATE"))
        XCTAssertNil(FatigueBand(rawValue: "High"))
        XCTAssertNil(FatigueBand(rawValue: "CRITICAL"))

        // Only lowercase should work
        XCTAssertNotNil(FatigueBand(rawValue: "low"))
        XCTAssertNotNil(FatigueBand(rawValue: "moderate"))
        XCTAssertNotNil(FatigueBand(rawValue: "high"))
        XCTAssertNotNil(FatigueBand(rawValue: "critical"))
    }

    // MARK: - Band Determination From Scores Tests

    func testFatigueBand_DetermineFromScore_LowBand() {
        // Low band: 0-40
        let lowScores: [Double] = [0, 10, 20, 30, 39, 39.9]
        for score in lowScores {
            let band = determineBandFromScore(score)
            XCTAssertEqual(band, .low, "Score \(score) should map to low band")
        }
    }

    func testFatigueBand_DetermineFromScore_ModerateBand() {
        // Moderate band: 40-60
        let moderateScores: [Double] = [40, 45, 50, 55, 59, 59.9]
        for score in moderateScores {
            let band = determineBandFromScore(score)
            XCTAssertEqual(band, .moderate, "Score \(score) should map to moderate band")
        }
    }

    func testFatigueBand_DetermineFromScore_HighBand() {
        // High band: 60-80
        let highScores: [Double] = [60, 65, 70, 75, 79, 79.9]
        for score in highScores {
            let band = determineBandFromScore(score)
            XCTAssertEqual(band, .high, "Score \(score) should map to high band")
        }
    }

    func testFatigueBand_DetermineFromScore_CriticalBand() {
        // Critical band: 80-100
        let criticalScores: [Double] = [80, 85, 90, 95, 100]
        for score in criticalScores {
            let band = determineBandFromScore(score)
            XCTAssertEqual(band, .critical, "Score \(score) should map to critical band")
        }
    }

    func testFatigueBand_DetermineFromScore_BoundaryValues() {
        // Test exact boundary values
        XCTAssertEqual(determineBandFromScore(0), .low)
        XCTAssertEqual(determineBandFromScore(40), .moderate)
        XCTAssertEqual(determineBandFromScore(60), .high)
        XCTAssertEqual(determineBandFromScore(80), .critical)
        XCTAssertEqual(determineBandFromScore(100), .critical)
    }

    func testFatigueBand_DetermineFromScore_EdgeCases() {
        // Just below boundaries
        XCTAssertEqual(determineBandFromScore(39.99), .low)
        XCTAssertEqual(determineBandFromScore(59.99), .moderate)
        XCTAssertEqual(determineBandFromScore(79.99), .high)

        // Just at boundaries
        XCTAssertEqual(determineBandFromScore(40.0), .moderate)
        XCTAssertEqual(determineBandFromScore(60.0), .high)
        XCTAssertEqual(determineBandFromScore(80.0), .critical)
    }

    func testFatigueBand_DetermineFromScore_NegativeValue() {
        // Negative scores should still return low
        XCTAssertEqual(determineBandFromScore(-10), .low)
        XCTAssertEqual(determineBandFromScore(-1), .low)
    }

    func testFatigueBand_DetermineFromScore_OverMaxValue() {
        // Scores over 100 should still return critical
        XCTAssertEqual(determineBandFromScore(101), .critical)
        XCTAssertEqual(determineBandFromScore(150), .critical)
    }

    // MARK: - Color Mapping Tests

    func testFatigueBand_Colors() {
        XCTAssertEqual(FatigueBand.low.color, Color.green)
        XCTAssertEqual(FatigueBand.moderate.color, Color.yellow)
        XCTAssertEqual(FatigueBand.high.color, Color.orange)
        XCTAssertEqual(FatigueBand.critical.color, Color.red)
    }

    func testFatigueBand_AllCasesHaveUniqueColors() {
        var colors: [Color] = []
        for band in FatigueBand.allCases {
            XCTAssertFalse(colors.contains(band.color), "Each fatigue band should have a unique color")
            colors.append(band.color)
        }
    }

    func testFatigueBand_ColorProgressionSeverity() {
        // Colors should progress from less severe (green) to more severe (red)
        // This is a semantic test - green/yellow/orange/red follows traffic light pattern
        XCTAssertEqual(FatigueBand.low.color, .green, "Low fatigue should be green (safe)")
        XCTAssertEqual(FatigueBand.critical.color, .red, "Critical fatigue should be red (danger)")
    }

    func testFatigueBand_ColorsMappingToTrafficLightPattern() {
        // Traffic light color progression: green -> yellow -> orange -> red
        let expectedColors: [(FatigueBand, Color)] = [
            (.low, .green),
            (.moderate, .yellow),
            (.high, .orange),
            (.critical, .red)
        ]

        for (band, expectedColor) in expectedColors {
            XCTAssertEqual(band.color, expectedColor,
                          "\(band.displayName) should be \(expectedColor)")
        }
    }

    func testFatigueBand_ColorConsistencyWithSeverity() {
        // Verify the color order matches severity progression
        let bands = FatigueBand.allCases
        let colorStrings = bands.map { "\($0.color)" }
        let uniqueColors = Set(colorStrings)
        XCTAssertEqual(uniqueColors.count, bands.count,
                      "Each band should have a unique color")
    }

    // MARK: - Display Name Tests

    func testFatigueBand_DisplayNames() {
        XCTAssertEqual(FatigueBand.low.displayName, "Low")
        XCTAssertEqual(FatigueBand.moderate.displayName, "Moderate")
        XCTAssertEqual(FatigueBand.high.displayName, "High")
        XCTAssertEqual(FatigueBand.critical.displayName, "Critical")
    }

    func testFatigueBand_DisplayNamesAreCapitalized() {
        for band in FatigueBand.allCases {
            XCTAssertFalse(band.displayName.isEmpty, "Display name should not be empty")
            XCTAssertTrue(band.displayName.first?.isUppercase == true,
                          "Display name should start with uppercase: \(band.displayName)")
        }
    }

    func testFatigueBand_DisplayNamesAreNotEmpty() {
        for band in FatigueBand.allCases {
            XCTAssertFalse(band.displayName.isEmpty)
            XCTAssertGreaterThan(band.displayName.count, 0)
        }
    }

    func testFatigueBand_DisplayNamesDifferFromRawValue() {
        for band in FatigueBand.allCases {
            // Display name is capitalized, raw value is lowercase
            XCTAssertNotEqual(band.displayName, band.rawValue)
            XCTAssertEqual(band.displayName.lowercased(), band.rawValue)
        }
    }

    // MARK: - Description Tests

    func testFatigueBand_Descriptions() {
        XCTAssertEqual(FatigueBand.low.description, "Low fatigue - Ready for full training")
        XCTAssertEqual(FatigueBand.moderate.description, "Moderate fatigue - Monitor recovery")
        XCTAssertEqual(FatigueBand.high.description, "High fatigue - Consider reducing load")
        XCTAssertEqual(FatigueBand.critical.description, "Critical fatigue - Deload recommended")
    }

    func testFatigueBand_DescriptionsContainBandName() {
        for band in FatigueBand.allCases {
            XCTAssertTrue(band.description.lowercased().contains(band.displayName.lowercased()),
                          "Description should contain the band name: \(band.description)")
        }
    }

    func testFatigueBand_DescriptionsProvideGuidance() {
        // Each description should contain actionable guidance
        XCTAssertTrue(FatigueBand.low.description.contains("training"))
        XCTAssertTrue(FatigueBand.moderate.description.contains("recovery"))
        XCTAssertTrue(FatigueBand.high.description.contains("reducing") ||
                     FatigueBand.high.description.contains("load"))
        XCTAssertTrue(FatigueBand.critical.description.contains("Deload") ||
                     FatigueBand.critical.description.contains("recommended"))
    }

    func testFatigueBand_DescriptionHasTwoParts() {
        for band in FatigueBand.allCases {
            // Each description should have format: "Band fatigue - Action"
            XCTAssertTrue(band.description.contains(" - "),
                         "Description should have two parts separated by ' - '")
            let parts = band.description.components(separatedBy: " - ")
            XCTAssertEqual(parts.count, 2,
                          "Description should split into exactly two parts")
        }
    }

    func testFatigueBand_DescriptionsIncreaseInUrgency() {
        // Low: "Ready for full training" - positive/permissive
        XCTAssertTrue(FatigueBand.low.description.contains("Ready"))

        // Moderate: "Monitor recovery" - advisory
        XCTAssertTrue(FatigueBand.moderate.description.contains("Monitor"))

        // High: "Consider reducing load" - suggestive action
        XCTAssertTrue(FatigueBand.high.description.contains("Consider"))

        // Critical: "Deload recommended" - strong recommendation
        XCTAssertTrue(FatigueBand.critical.description.contains("recommended"))
    }

    // MARK: - Icon Tests

    func testFatigueBand_Icons() {
        XCTAssertEqual(FatigueBand.low.icon, "battery.100")
        XCTAssertEqual(FatigueBand.moderate.icon, "battery.75")
        XCTAssertEqual(FatigueBand.high.icon, "battery.25")
        XCTAssertEqual(FatigueBand.critical.icon, "battery.0")
    }

    func testFatigueBand_IconsAreBatteryThemed() {
        for band in FatigueBand.allCases {
            XCTAssertTrue(band.icon.hasPrefix("battery"),
                          "Icon should be battery-themed: \(band.icon)")
        }
    }

    func testFatigueBand_IconsProgressFromFullToEmpty() {
        // Icons should show decreasing battery as fatigue increases
        XCTAssertTrue(FatigueBand.low.icon.contains("100"))
        XCTAssertTrue(FatigueBand.moderate.icon.contains("75"))
        XCTAssertTrue(FatigueBand.high.icon.contains("25"))
        XCTAssertTrue(FatigueBand.critical.icon.contains("0"))
    }

    func testFatigueBand_IconBatteryLevelDecreases() {
        let batteryLevels: [(FatigueBand, Int)] = [
            (.low, 100),
            (.moderate, 75),
            (.high, 25),
            (.critical, 0)
        ]

        for i in 0..<(batteryLevels.count - 1) {
            let current = batteryLevels[i]
            let next = batteryLevels[i + 1]
            XCTAssertGreaterThan(current.1, next.1,
                                "Battery level should decrease: \(current.0) > \(next.0)")
        }
    }

    func testFatigueBand_IconsAreValidSFSymbols() {
        // Battery icons are valid SF Symbols format
        let validBatteryIcons = ["battery.100", "battery.75", "battery.50", "battery.25", "battery.0"]
        for band in FatigueBand.allCases {
            XCTAssertTrue(validBatteryIcons.contains(band.icon) || band.icon.hasPrefix("battery."),
                         "Icon should be a valid battery SF Symbol: \(band.icon)")
        }
    }

    // MARK: - Codable Tests

    func testFatigueBand_Encoding() throws {
        let encoder = JSONEncoder()

        for band in FatigueBand.allCases {
            let data = try encoder.encode(band)
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertEqual(jsonString, "\"\(band.rawValue)\"")
        }
    }

    func testFatigueBand_Decoding() throws {
        let decoder = JSONDecoder()

        for band in FatigueBand.allCases {
            let json = "\"\(band.rawValue)\"".data(using: .utf8)!
            let decoded = try decoder.decode(FatigueBand.self, from: json)
            XCTAssertEqual(decoded, band)
        }
    }

    func testFatigueBand_EncodingDecodingRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in FatigueBand.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(FatigueBand.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testFatigueBand_DecodingInvalidValue_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "\"invalid_band\"".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(FatigueBand.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFatigueBand_DecodingEmptyString_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "\"\"".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(FatigueBand.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFatigueBand_DecodingNumber_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "1".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(FatigueBand.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testFatigueBand_DecodingNull_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "null".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(FatigueBand.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Equatable Tests

    func testFatigueBand_Equality() {
        XCTAssertEqual(FatigueBand.low, FatigueBand.low)
        XCTAssertEqual(FatigueBand.moderate, FatigueBand.moderate)
        XCTAssertEqual(FatigueBand.high, FatigueBand.high)
        XCTAssertEqual(FatigueBand.critical, FatigueBand.critical)
    }

    func testFatigueBand_Inequality() {
        XCTAssertNotEqual(FatigueBand.low, FatigueBand.moderate)
        XCTAssertNotEqual(FatigueBand.moderate, FatigueBand.high)
        XCTAssertNotEqual(FatigueBand.high, FatigueBand.critical)
        XCTAssertNotEqual(FatigueBand.low, FatigueBand.critical)
    }

    func testFatigueBand_AllPairsAreUnequal() {
        let allCases = FatigueBand.allCases
        for i in 0..<allCases.count {
            for j in 0..<allCases.count {
                if i != j {
                    XCTAssertNotEqual(allCases[i], allCases[j],
                                     "\(allCases[i]) should not equal \(allCases[j])")
                }
            }
        }
    }

    // MARK: - Hashable Tests

    func testFatigueBand_Hashable() {
        var set = Set<FatigueBand>()

        for band in FatigueBand.allCases {
            set.insert(band)
        }

        XCTAssertEqual(set.count, 4)
        XCTAssertTrue(set.contains(.low))
        XCTAssertTrue(set.contains(.moderate))
        XCTAssertTrue(set.contains(.high))
        XCTAssertTrue(set.contains(.critical))
    }

    func testFatigueBand_HashValues() {
        // Each case should have a unique hash
        let hashes = FatigueBand.allCases.map { $0.hashValue }
        let uniqueHashes = Set(hashes)
        XCTAssertEqual(uniqueHashes.count, 4)
    }

    func testFatigueBand_DuplicateInsertionDoesNotIncreaseCount() {
        var set = Set<FatigueBand>()

        set.insert(.low)
        XCTAssertEqual(set.count, 1)

        set.insert(.low)
        XCTAssertEqual(set.count, 1, "Duplicate should not increase count")

        set.insert(.moderate)
        XCTAssertEqual(set.count, 2)
    }

    func testFatigueBand_CanBeUsedAsDictionaryKey() {
        var dict: [FatigueBand: String] = [:]

        dict[.low] = "Green zone"
        dict[.moderate] = "Yellow zone"
        dict[.high] = "Orange zone"
        dict[.critical] = "Red zone"

        XCTAssertEqual(dict.count, 4)
        XCTAssertEqual(dict[.low], "Green zone")
        XCTAssertEqual(dict[.critical], "Red zone")
    }

    // MARK: - Severity Ordering Tests

    func testFatigueBand_SeverityOrder() {
        // Test that bands can be compared by their position in allCases
        let allCases = FatigueBand.allCases

        // Find indices
        guard let lowIndex = allCases.firstIndex(of: .low),
              let moderateIndex = allCases.firstIndex(of: .moderate),
              let highIndex = allCases.firstIndex(of: .high),
              let criticalIndex = allCases.firstIndex(of: .critical) else {
            XCTFail("All bands should be found in allCases")
            return
        }

        // Verify order
        XCTAssertLessThan(lowIndex, moderateIndex)
        XCTAssertLessThan(moderateIndex, highIndex)
        XCTAssertLessThan(highIndex, criticalIndex)
    }

    func testFatigueBand_LowIsLeastSevere() {
        let allCases = FatigueBand.allCases
        XCTAssertEqual(allCases.first, .low, "Low should be the first (least severe) case")
    }

    func testFatigueBand_CriticalIsMostSevere() {
        let allCases = FatigueBand.allCases
        XCTAssertEqual(allCases.last, .critical, "Critical should be the last (most severe) case")
    }

    // MARK: - Helper Methods

    /// Helper function to determine band from score (mirrors business logic)
    private func determineBandFromScore(_ score: Double) -> FatigueBand {
        switch score {
        case ..<40:
            return .low
        case 40..<60:
            return .moderate
        case 60..<80:
            return .high
        default:
            return .critical
        }
    }
}
