//
//  DeloadUrgencyTests.swift
//  PTPerformanceTests
//
//  Unit tests for DeloadUrgency enum
//  Tests all cases, UI properties, and threshold determinations
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

    func testDeloadUrgency_CaseCount() {
        XCTAssertEqual(DeloadUrgency.allCases.count, 4)
    }

    func testDeloadUrgency_NoneIsFirst() {
        XCTAssertEqual(DeloadUrgency.allCases.first, DeloadUrgency.none)
    }

    func testDeloadUrgency_RequiredIsLast() {
        XCTAssertEqual(DeloadUrgency.allCases.last, .required)
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
        XCTAssertNil(DeloadUrgency(rawValue: "critical"))
        XCTAssertNil(DeloadUrgency(rawValue: " none"))
        XCTAssertNil(DeloadUrgency(rawValue: "none "))
    }

    func testDeloadUrgency_RawValueCaseSensitivity() {
        XCTAssertNil(DeloadUrgency(rawValue: "None"))
        XCTAssertNil(DeloadUrgency(rawValue: "SUGGESTED"))
        XCTAssertNil(DeloadUrgency(rawValue: "Recommended"))
        XCTAssertNil(DeloadUrgency(rawValue: "REQUIRED"))

        // Only lowercase should work
        XCTAssertNotNil(DeloadUrgency(rawValue: "none"))
        XCTAssertNotNil(DeloadUrgency(rawValue: "suggested"))
        XCTAssertNotNil(DeloadUrgency(rawValue: "recommended"))
        XCTAssertNotNil(DeloadUrgency(rawValue: "required"))
    }

    // MARK: - Threshold Determination Tests

    func testDeloadUrgency_ThresholdDetermination_NoneLevel() {
        // None: fatigue score < 40, no consecutive low days
        let urgency = determineUrgency(fatigueScore: 30, consecutiveLowDays: 0, acr: 1.0)
        XCTAssertEqual(urgency, .none)
    }

    func testDeloadUrgency_ThresholdDetermination_SuggestedLevel() {
        // Suggested: moderate fatigue (40-60) or 1-2 consecutive low days
        let urgency1 = determineUrgency(fatigueScore: 50, consecutiveLowDays: 1, acr: 1.1)
        XCTAssertEqual(urgency1, .suggested)

        let urgency2 = determineUrgency(fatigueScore: 45, consecutiveLowDays: 2, acr: 1.15)
        XCTAssertEqual(urgency2, .suggested)
    }

    func testDeloadUrgency_ThresholdDetermination_RecommendedLevel() {
        // Recommended: high fatigue (60-80) or 3-4 consecutive low days or ACR > 1.3
        let urgency1 = determineUrgency(fatigueScore: 70, consecutiveLowDays: 3, acr: 1.35)
        XCTAssertEqual(urgency1, .recommended)

        let urgency2 = determineUrgency(fatigueScore: 65, consecutiveLowDays: 4, acr: 1.4)
        XCTAssertEqual(urgency2, .recommended)
    }

    func testDeloadUrgency_ThresholdDetermination_RequiredLevel() {
        // Required: critical fatigue (>80) or 5+ consecutive low days or ACR > 1.5
        let urgency1 = determineUrgency(fatigueScore: 85, consecutiveLowDays: 5, acr: 1.6)
        XCTAssertEqual(urgency1, .required)

        let urgency2 = determineUrgency(fatigueScore: 90, consecutiveLowDays: 7, acr: 2.0)
        XCTAssertEqual(urgency2, .required)
    }

    func testDeloadUrgency_ThresholdDetermination_BoundaryValues() {
        // Test exact boundary values
        XCTAssertEqual(determineUrgency(fatigueScore: 39.9, consecutiveLowDays: 0, acr: 1.0), .none)
        XCTAssertEqual(determineUrgency(fatigueScore: 40.0, consecutiveLowDays: 1, acr: 1.1), .suggested)
        XCTAssertEqual(determineUrgency(fatigueScore: 59.9, consecutiveLowDays: 2, acr: 1.2), .suggested)
        XCTAssertEqual(determineUrgency(fatigueScore: 60.0, consecutiveLowDays: 3, acr: 1.35), .recommended)
        XCTAssertEqual(determineUrgency(fatigueScore: 79.9, consecutiveLowDays: 4, acr: 1.4), .recommended)
        XCTAssertEqual(determineUrgency(fatigueScore: 80.0, consecutiveLowDays: 5, acr: 1.5), .required)
    }

    func testDeloadUrgency_ThresholdDetermination_ConsecutiveDaysOverrides() {
        // Even with low fatigue score, many consecutive low days should increase urgency
        let urgency = determineUrgency(fatigueScore: 45, consecutiveLowDays: 7, acr: 1.2)
        XCTAssertEqual(urgency, .required, "7+ consecutive low days should require deload")
    }

    func testDeloadUrgency_ThresholdDetermination_HighACROverrides() {
        // High ACR can increase urgency even with moderate fatigue
        let urgency = determineUrgency(fatigueScore: 55, consecutiveLowDays: 2, acr: 1.8)
        XCTAssertEqual(urgency, .required, "Very high ACR should require deload")
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

    func testDeloadUrgency_TitlesAreUserFriendly() {
        for urgency in DeloadUrgency.allCases {
            // Titles should start with capital letter
            XCTAssertTrue(urgency.title.first?.isUppercase == true)

            // Titles should not contain technical jargon
            XCTAssertFalse(urgency.title.contains("ACR"))
            XCTAssertFalse(urgency.title.contains("ratio"))
        }
    }

    func testDeloadUrgency_TitlesProgressInUrgency() {
        // Verify titles convey increasing urgency
        XCTAssertTrue(DeloadUrgency.none.title.contains("No"),
                     "None should indicate no action needed")
        XCTAssertTrue(DeloadUrgency.suggested.title.contains("Suggested"),
                     "Suggested should be soft recommendation")
        XCTAssertTrue(DeloadUrgency.recommended.title.contains("Recommended"),
                     "Recommended should be stronger than suggested")
        XCTAssertTrue(DeloadUrgency.required.title.contains("Required"),
                     "Required should indicate mandatory action")
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

    func testDeloadUrgency_SubtitlesIncreaseInSeverity() {
        // None subtitle should be positive/permissive
        XCTAssertTrue(DeloadUrgency.none.subtitle.contains("Continue"))

        // Required subtitle should warn about consequences
        XCTAssertTrue(DeloadUrgency.required.subtitle.contains("prevent") ||
                     DeloadUrgency.required.subtitle.contains("overtraining"))
    }

    func testDeloadUrgency_SubtitlesAreCompleteSentences() {
        for urgency in DeloadUrgency.allCases {
            // Should start with capital letter
            XCTAssertTrue(urgency.subtitle.first?.isUppercase == true,
                         "Subtitle should start with capital: \(urgency.subtitle)")
        }
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

    func testDeloadUrgency_ColorsMappingToTrafficLightPattern() {
        // Traffic light color progression: green -> yellow -> orange -> red
        let expectedColors: [(DeloadUrgency, Color)] = [
            (.none, .green),
            (.suggested, .yellow),
            (.recommended, .orange),
            (.required, .red)
        ]

        for (urgency, expectedColor) in expectedColors {
            XCTAssertEqual(urgency.color, expectedColor,
                          "\(urgency.rawValue) should be \(expectedColor)")
        }
    }

    func testDeloadUrgency_ColorConsistencyAcrossInstances() {
        // Same urgency should always return same color
        let urgency1 = DeloadUrgency.recommended
        let urgency2 = DeloadUrgency(rawValue: "recommended")!

        XCTAssertEqual(urgency1.color, urgency2.color)
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

    func testDeloadUrgency_IconsAreUnique() {
        let icons = DeloadUrgency.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)
        XCTAssertEqual(uniqueIcons.count, icons.count,
                      "Each urgency should have a unique icon")
    }

    func testDeloadUrgency_IconShapeProgression() {
        // Shapes should progress: circle -> circle -> triangle -> octagon
        XCTAssertTrue(DeloadUrgency.none.icon.contains("circle"))
        XCTAssertTrue(DeloadUrgency.suggested.icon.contains("circle"))
        XCTAssertTrue(DeloadUrgency.recommended.icon.contains("triangle"))
        XCTAssertTrue(DeloadUrgency.required.icon.contains("octagon"))
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

    func testDeloadUrgency_DecodingEmptyString_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "\"\"".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(DeloadUrgency.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDeloadUrgency_DecodingNumber_Throws() {
        let decoder = JSONDecoder()
        let invalidJson = "1".data(using: .utf8)!

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

    func testDeloadUrgency_AllPairsAreUnequal() {
        let allCases = DeloadUrgency.allCases
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

    func testDeloadUrgency_CanBeUsedAsDictionaryKey() {
        var dict: [DeloadUrgency: String] = [:]

        dict[.none] = "All good"
        dict[.suggested] = "Consider it"
        dict[.recommended] = "Should do"
        dict[.required] = "Must do"

        XCTAssertEqual(dict.count, 4)
        XCTAssertEqual(dict[.none], "All good")
        XCTAssertEqual(dict[.required], "Must do")
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

    func testDeloadUrgency_TitleAndSubtitleAreDistinct() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertNotEqual(urgency.title, urgency.subtitle,
                             "Title and subtitle should be different for \(urgency)")
        }
    }

    func testDeloadUrgency_SubtitleIsMoreDescriptive() {
        for urgency in DeloadUrgency.allCases {
            XCTAssertGreaterThan(urgency.subtitle.count, urgency.title.count,
                                "Subtitle should be longer than title for \(urgency)")
        }
    }

    // MARK: - Severity Ordering Tests

    func testDeloadUrgency_SeverityOrder() {
        let allCases = DeloadUrgency.allCases

        guard let noneIndex = allCases.firstIndex(of: .none),
              let suggestedIndex = allCases.firstIndex(of: .suggested),
              let recommendedIndex = allCases.firstIndex(of: .recommended),
              let requiredIndex = allCases.firstIndex(of: .required) else {
            XCTFail("All urgencies should be found in allCases")
            return
        }

        XCTAssertLessThan(noneIndex, suggestedIndex)
        XCTAssertLessThan(suggestedIndex, recommendedIndex)
        XCTAssertLessThan(recommendedIndex, requiredIndex)
    }

    func testDeloadUrgency_NoneIsLeastUrgent() {
        let allCases = DeloadUrgency.allCases
        XCTAssertEqual(allCases.first, DeloadUrgency.none, "None should be the first (least urgent) case")
    }

    func testDeloadUrgency_RequiredIsMostUrgent() {
        let allCases = DeloadUrgency.allCases
        XCTAssertEqual(allCases.last, .required, "Required should be the last (most urgent) case")
    }

    // MARK: - Mapping to FatigueBand Tests

    func testDeloadUrgency_MappingFromFatigueBand() {
        // Low fatigue -> None urgency
        XCTAssertEqual(urgencyFromBand(.low), .none)

        // Moderate fatigue -> Suggested urgency
        XCTAssertEqual(urgencyFromBand(.moderate), .suggested)

        // High fatigue -> Recommended urgency
        XCTAssertEqual(urgencyFromBand(.high), .recommended)

        // Critical fatigue -> Required urgency
        XCTAssertEqual(urgencyFromBand(.critical), .required)
    }

    // MARK: - Helper Methods

    /// Determine urgency based on fatigue metrics (mirrors business logic)
    private func determineUrgency(fatigueScore: Double, consecutiveLowDays: Int, acr: Double) -> DeloadUrgency {
        // ACR-based overrides
        if acr >= 1.5 || consecutiveLowDays >= 5 {
            return .required
        }

        // Score-based determination
        switch fatigueScore {
        case ..<40:
            if consecutiveLowDays == 0 && acr < 1.2 {
                return .none
            }
            return consecutiveLowDays >= 3 ? .recommended : .suggested
        case 40..<60:
            return consecutiveLowDays >= 3 ? .recommended : .suggested
        case 60..<80:
            return .recommended
        default:
            return .required
        }
    }

    /// Map fatigue band to urgency
    private func urgencyFromBand(_ band: FatigueBand) -> DeloadUrgency {
        switch band {
        case .low: return .none
        case .moderate: return .suggested
        case .high: return .recommended
        case .critical: return .required
        }
    }
}
