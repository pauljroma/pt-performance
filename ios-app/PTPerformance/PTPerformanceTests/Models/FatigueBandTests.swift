//
//  FatigueBandTests.swift
//  PTPerformanceTests
//
//  Unit tests for FatigueBand enum
//  Tests all cases, color mappings, and display properties
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
}
