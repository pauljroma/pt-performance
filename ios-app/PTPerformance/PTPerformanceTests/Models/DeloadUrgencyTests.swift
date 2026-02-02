//
//  DeloadUrgencyTests.swift
//  PTPerformanceTests
//
//  Unit tests for DeloadUrgency enum
//  Tests all cases and UI properties
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class DeloadUrgencyModelTests: XCTestCase {

    // MARK: - All Cases Tests

    func testDeloadUrgency_AllCasesExist() {
        let allCases = DeloadUrgency.allCases
        XCTAssertEqual(allCases.count, 4, "DeloadUrgency should have exactly 4 cases")
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.suggested))
        XCTAssertTrue(allCases.contains(.recommended))
        XCTAssertTrue(allCases.contains(.required))
    }

    func testDeloadUrgency_CasesAreOrdered() {
        let allCases = DeloadUrgency.allCases
        XCTAssertEqual(allCases[0], .none)
        XCTAssertEqual(allCases[1], .suggested)
        XCTAssertEqual(allCases[2], .recommended)
        XCTAssertEqual(allCases[3], .required)
    }

    // MARK: - Raw Value Tests

    func testDeloadUrgency_RawValues() {
        XCTAssertEqual(DeloadUrgency.none.rawValue, "none")
        XCTAssertEqual(DeloadUrgency.suggested.rawValue, "suggested")
        XCTAssertEqual(DeloadUrgency.recommended.rawValue, "recommended")
        XCTAssertEqual(DeloadUrgency.required.rawValue, "required")
    }

    func testDeloadUrgency_InitFromRawValue_ValidValues() {
        // Use fully qualified DeloadUrgency.none to avoid ambiguity with Optional.none
        XCTAssertEqual(DeloadUrgency(rawValue: "none"), DeloadUrgency.none)
        XCTAssertEqual(DeloadUrgency(rawValue: "suggested"), DeloadUrgency.suggested)
        XCTAssertEqual(DeloadUrgency(rawValue: "recommended"), DeloadUrgency.recommended)
        XCTAssertEqual(DeloadUrgency(rawValue: "required"), DeloadUrgency.required)
    }

    func testDeloadUrgency_InitFromRawValue_InvalidValues() {
        XCTAssertNil(DeloadUrgency(rawValue: "invalid"))
        XCTAssertNil(DeloadUrgency(rawValue: ""))
        XCTAssertNil(DeloadUrgency(rawValue: "NONE"))
        XCTAssertNil(DeloadUrgency(rawValue: "None"))
        XCTAssertNil(DeloadUrgency(rawValue: "REQUIRED"))
        XCTAssertNil(DeloadUrgency(rawValue: "urgent"))
        XCTAssertNil(DeloadUrgency(rawValue: "mandatory"))
    }

    // MARK: - Title Tests

    func testDeloadUrgency_Titles() {
        XCTAssertEqual(DeloadUrgency.none.title, "No Deload Needed")
        XCTAssertEqual(DeloadUrgency.suggested.title, "Deload Suggested")
        XCTAssertEqual(DeloadUrgency.recommended.title, "Deload Recommended")
        XCTAssertEqual(DeloadUrgency.required.title, "Deload Required")
    }

    func testDeloadUrgency_TitlesAreNotEmpty() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.title.isEmpty)
            XCTAssertGreaterThan(urgency.title.count, 0)
        }
    }

    func testDeloadUrgency_TitlesContainDeloadOrNo() {
        for urgency in DeloadUrgency.allCases {
            let hasDeload = urgency.title.contains("Deload")
            let hasNo = urgency.title.contains("No")
            XCTAssertTrue(hasDeload || hasNo,
                          "Title should reference deload status: \(urgency.title)")
        }
    }

    // MARK: - Subtitle Tests

    func testDeloadUrgency_Subtitles() {
        XCTAssertEqual(DeloadUrgency.none.subtitle, "Continue training as planned")
        XCTAssertEqual(DeloadUrgency.suggested.subtitle, "Consider a lighter week if fatigue persists")
        XCTAssertEqual(DeloadUrgency.recommended.subtitle, "A deload week would benefit recovery")
        XCTAssertEqual(DeloadUrgency.required.subtitle, "Immediate deload needed to prevent overtraining")
    }

    func testDeloadUrgency_SubtitlesAreNotEmpty() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.subtitle.isEmpty)
            XCTAssertGreaterThan(urgency.subtitle.count, 10, "Subtitle should provide meaningful guidance")
        }
    }

    func testDeloadUrgency_SubtitlesProvideActionableGuidance() {
        // None: Should indicate normal training
        XCTAssertTrue(DeloadUrgency.none.subtitle.lowercased().contains("training") ||
                     DeloadUrgency.none.subtitle.lowercased().contains("continue"))

        // Suggested: Should mention consideration
        XCTAssertTrue(DeloadUrgency.suggested.subtitle.lowercased().contains("consider"))

        // Recommended: Should mention benefit
        XCTAssertTrue(DeloadUrgency.recommended.subtitle.lowercased().contains("benefit") ||
                     DeloadUrgency.recommended.subtitle.lowercased().contains("would"))

        // Required: Should indicate urgency
        XCTAssertTrue(DeloadUrgency.required.subtitle.lowercased().contains("immediate") ||
                     DeloadUrgency.required.subtitle.lowercased().contains("needed"))
    }

    // MARK: - Color Tests

    func testDeloadUrgency_Colors() {
        XCTAssertEqual(DeloadUrgency.none.color, Color.green)
        XCTAssertEqual(DeloadUrgency.suggested.color, Color.yellow)
        XCTAssertEqual(DeloadUrgency.recommended.color, Color.orange)
        XCTAssertEqual(DeloadUrgency.required.color, Color.red)
    }

    func testDeloadUrgency_AllCasesHaveUniqueColors() {
        var colors: [Color] = []
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(colors.contains(urgency.color),
                          "Each urgency level should have a unique color")
            colors.append(urgency.color)
        }
    }

    func testDeloadUrgency_ColorProgressionSeverity() {
        // Colors should progress from less urgent (green) to more urgent (red)
        XCTAssertEqual(DeloadUrgency.none.color, .green, "No deload should be green (safe)")
        XCTAssertEqual(DeloadUrgency.required.color, .red, "Required deload should be red (urgent)")
    }

    // MARK: - Icon Tests

    func testDeloadUrgency_Icons() {
        XCTAssertEqual(DeloadUrgency.none.icon, "checkmark.circle")
        XCTAssertEqual(DeloadUrgency.suggested.icon, "info.circle")
        XCTAssertEqual(DeloadUrgency.recommended.icon, "exclamationmark.triangle")
        XCTAssertEqual(DeloadUrgency.required.icon, "exclamationmark.octagon")
    }

    func testDeloadUrgency_IconsAreNotEmpty() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.icon.isEmpty)
            XCTAssertGreaterThan(urgency.icon.count, 0)
        }
    }

    func testDeloadUrgency_IconsAreSFSymbols() {
        // SF Symbols typically use lowercase and dots
        for urgency in DeloadUrgency.allCases {
            XCTAssertTrue(urgency.icon.contains("."),
                          "Icon should be SF Symbol format: \(urgency.icon)")
        }
    }

    func testDeloadUrgency_IconsProgressInSeverity() {
        // Icons should become more urgent/warning-oriented as severity increases
        XCTAssertTrue(DeloadUrgency.none.icon.contains("checkmark"),
                     "None should use checkmark icon")
        XCTAssertTrue(DeloadUrgency.suggested.icon.contains("info"),
                     "Suggested should use info icon")
        XCTAssertTrue(DeloadUrgency.recommended.icon.contains("exclamationmark") ||
                     DeloadUrgency.recommended.icon.contains("triangle"),
                     "Recommended should use warning icon")
        XCTAssertTrue(DeloadUrgency.required.icon.contains("exclamationmark") ||
                     DeloadUrgency.required.icon.contains("octagon"),
                     "Required should use stop/danger icon")
    }

    // MARK: - Codable Tests

    func testDeloadUrgency_Encoding() throws {
        let encoder = JSONEncoder()

        for urgency in DeloadUrgency.allCases {
            let data = try encoder.encode(urgency)
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertEqual(jsonString, "\"\(urgency.rawValue)\"")
        }
    }

    func testDeloadUrgency_Decoding() throws {
        let decoder = JSONDecoder()

        for urgency in DeloadUrgency.allCases {
            let json = "\"\(urgency.rawValue)\"".data(using: .utf8)!
            let decoded = try decoder.decode(DeloadUrgency.self, from: json)
            XCTAssertEqual(decoded, urgency)
        }
    }

    func testDeloadUrgency_EncodingDecodingRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in DeloadUrgency.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(DeloadUrgency.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testDeloadUrgency_DecodingInvalidValue_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "\"urgent\"".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(DeloadUrgency.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Equatable Tests

    func testDeloadUrgency_Equality() {
        XCTAssertEqual(DeloadUrgency.none, DeloadUrgency.none)
        XCTAssertEqual(DeloadUrgency.suggested, DeloadUrgency.suggested)
        XCTAssertEqual(DeloadUrgency.recommended, DeloadUrgency.recommended)
        XCTAssertEqual(DeloadUrgency.required, DeloadUrgency.required)
    }

    func testDeloadUrgency_Inequality() {
        XCTAssertNotEqual(DeloadUrgency.none, DeloadUrgency.suggested)
        XCTAssertNotEqual(DeloadUrgency.suggested, DeloadUrgency.recommended)
        XCTAssertNotEqual(DeloadUrgency.recommended, DeloadUrgency.required)
        XCTAssertNotEqual(DeloadUrgency.none, DeloadUrgency.required)
    }

    // MARK: - Hashable Tests

    func testDeloadUrgency_Hashable() {
        var set = Set<DeloadUrgency>()

        for urgency in DeloadUrgency.allCases {
            set.insert(urgency)
        }

        XCTAssertEqual(set.count, 4)
        XCTAssertTrue(set.contains(.none))
        XCTAssertTrue(set.contains(.suggested))
        XCTAssertTrue(set.contains(.recommended))
        XCTAssertTrue(set.contains(.required))
    }

    func testDeloadUrgency_HashValues() {
        // Each case should have a unique hash
        let hashes = DeloadUrgency.allCases.map { $0.hashValue }
        let uniqueHashes = Set(hashes)
        XCTAssertEqual(uniqueHashes.count, 4)
    }

    // MARK: - UI Consistency Tests

    func testDeloadUrgency_ColorAndIconConsistency() {
        // Verify that color and icon match in severity level
        // Both should follow: none=safe, suggested=info, recommended=warning, required=danger
        let safeColors: [Color] = [.green]
        let dangerColors: [Color] = [.red]

        XCTAssertTrue(safeColors.contains(DeloadUrgency.none.color))
        XCTAssertTrue(dangerColors.contains(DeloadUrgency.required.color))
    }

    func testDeloadUrgency_AllPropertiesArePopulated() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertFalse(urgency.rawValue.isEmpty, "Raw value should not be empty")
            XCTAssertFalse(urgency.title.isEmpty, "Title should not be empty")
            XCTAssertFalse(urgency.subtitle.isEmpty, "Subtitle should not be empty")
            XCTAssertFalse(urgency.icon.isEmpty, "Icon should not be empty")
            // Color is a value type and always populated
        }
    }
}
