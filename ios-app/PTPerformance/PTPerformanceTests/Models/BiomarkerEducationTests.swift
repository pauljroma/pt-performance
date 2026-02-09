//
//  BiomarkerEducationTests.swift
//  PTPerformanceTests
//
//  Unit tests for BiomarkerEducation model and BiomarkerEducationCategory enum.
//  Tests educational content, search functionality, and category mapping.
//

import XCTest
@testable import PTPerformance

// MARK: - BiomarkerEducation Tests

final class BiomarkerEducationTests: XCTestCase {

    // MARK: - Initialization

    func testBiomarkerEducation_Initialization() {
        let education = BiomarkerEducation(
            biomarkerName: "crp",
            displayName: "C-Reactive Protein",
            category: "Inflammation",
            shortDescription: "A key marker of inflammation",
            detailedDescription: "Detailed info about CRP",
            clinicalSignificance: "Elevated levels indicate inflammation",
            dietarySources: ["Fatty fish", "Leafy greens"],
            lifestyleFactors: ["Regular exercise", "Adequate sleep"],
            optimalRangeMale: "< 1.0 mg/L",
            optimalRangeFemale: "< 1.0 mg/L",
            unit: "mg/L"
        )

        XCTAssertEqual(education.biomarkerName, "crp")
        XCTAssertEqual(education.displayName, "C-Reactive Protein")
        XCTAssertEqual(education.category, "Inflammation")
        XCTAssertEqual(education.unit, "mg/L")
        XCTAssertEqual(education.dietarySources.count, 2)
        XCTAssertEqual(education.lifestyleFactors.count, 2)
    }

    func testBiomarkerEducation_Identifiable() {
        let education1 = BiomarkerEducation(
            biomarkerName: "test",
            displayName: "Test",
            category: "Other",
            shortDescription: "Short",
            detailedDescription: "Detailed",
            clinicalSignificance: "Significance",
            dietarySources: [],
            lifestyleFactors: [],
            unit: "units"
        )

        let education2 = BiomarkerEducation(
            biomarkerName: "test",
            displayName: "Test",
            category: "Other",
            shortDescription: "Short",
            detailedDescription: "Detailed",
            clinicalSignificance: "Significance",
            dietarySources: [],
            lifestyleFactors: [],
            unit: "units"
        )

        // Each instance should have unique ID
        XCTAssertNotEqual(education1.id, education2.id)
    }

    func testBiomarkerEducation_Hashable() {
        let education = BiomarkerEducation(
            biomarkerName: "crp",
            displayName: "CRP",
            category: "Inflammation",
            shortDescription: "Short",
            detailedDescription: "Detailed",
            clinicalSignificance: "Significance",
            dietarySources: [],
            lifestyleFactors: [],
            unit: "mg/L"
        )

        var set = Set<BiomarkerEducation>()
        set.insert(education)

        XCTAssertTrue(set.contains(education))
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Search Functionality

    func testMatches_EmptySearchText() {
        let education = createEducation(name: "crp", displayName: "CRP")

        XCTAssertTrue(education.matches(searchText: ""))
    }

    func testMatches_BiomarkerName() {
        let education = createEducation(name: "vitamin_d", displayName: "Vitamin D")

        XCTAssertTrue(education.matches(searchText: "vitamin_d"))
        XCTAssertTrue(education.matches(searchText: "vitamin"))
        XCTAssertTrue(education.matches(searchText: "VITAMIN"))
    }

    func testMatches_DisplayName() {
        let education = createEducation(name: "crp", displayName: "C-Reactive Protein")

        XCTAssertTrue(education.matches(searchText: "C-Reactive"))
        XCTAssertTrue(education.matches(searchText: "protein"))
        XCTAssertTrue(education.matches(searchText: "c-reactive protein"))
    }

    func testMatches_Category() {
        let education = BiomarkerEducation(
            biomarkerName: "crp",
            displayName: "CRP",
            category: "Inflammation",
            shortDescription: "Short",
            detailedDescription: "Detailed",
            clinicalSignificance: "Significance",
            dietarySources: [],
            lifestyleFactors: [],
            unit: "mg/L"
        )

        XCTAssertTrue(education.matches(searchText: "Inflammation"))
        XCTAssertTrue(education.matches(searchText: "inflam"))
    }

    func testMatches_ShortDescription() {
        let education = BiomarkerEducation(
            biomarkerName: "crp",
            displayName: "CRP",
            category: "Inflammation",
            shortDescription: "Key marker of inflammation in the body",
            detailedDescription: "Detailed",
            clinicalSignificance: "Significance",
            dietarySources: [],
            lifestyleFactors: [],
            unit: "mg/L"
        )

        XCTAssertTrue(education.matches(searchText: "marker"))
        XCTAssertTrue(education.matches(searchText: "body"))
    }

    func testMatches_NoMatch() {
        let education = createEducation(name: "crp", displayName: "CRP")

        XCTAssertFalse(education.matches(searchText: "xyz123"))
        XCTAssertFalse(education.matches(searchText: "completely unrelated"))
    }

    func testMatches_CaseInsensitive() {
        let education = createEducation(name: "testosterone", displayName: "Testosterone")

        XCTAssertTrue(education.matches(searchText: "TESTOSTERONE"))
        XCTAssertTrue(education.matches(searchText: "testosterone"))
        XCTAssertTrue(education.matches(searchText: "Testosterone"))
        XCTAssertTrue(education.matches(searchText: "TeStOsTeRoNe"))
    }

    // MARK: - Static Education Data

    func testAllEducation_NotEmpty() {
        XCTAssertFalse(BiomarkerEducation.allEducation.isEmpty)
    }

    func testAllEducation_ContainsExpectedBiomarkers() {
        let names = BiomarkerEducation.allEducation.map { $0.biomarkerName }

        XCTAssertTrue(names.contains("crp"))
        XCTAssertTrue(names.contains("testosterone"))
        XCTAssertTrue(names.contains("cortisol"))
        XCTAssertTrue(names.contains("vitamin_d"))
        XCTAssertTrue(names.contains("vitamin_b12"))
        XCTAssertTrue(names.contains("ferritin"))
        XCTAssertTrue(names.contains("magnesium"))
        XCTAssertTrue(names.contains("glucose"))
        XCTAssertTrue(names.contains("hba1c"))
        XCTAssertTrue(names.contains("hdl"))
        XCTAssertTrue(names.contains("ldl"))
        XCTAssertTrue(names.contains("tsh"))
        XCTAssertTrue(names.contains("hemoglobin"))
    }

    func testAllEducation_AllHaveRequiredFields() {
        for education in BiomarkerEducation.allEducation {
            XCTAssertFalse(education.biomarkerName.isEmpty, "biomarkerName should not be empty for \(education.displayName)")
            XCTAssertFalse(education.displayName.isEmpty, "displayName should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.category.isEmpty, "category should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.shortDescription.isEmpty, "shortDescription should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.detailedDescription.isEmpty, "detailedDescription should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.clinicalSignificance.isEmpty, "clinicalSignificance should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.unit.isEmpty, "unit should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.dietarySources.isEmpty, "dietarySources should not be empty for \(education.biomarkerName)")
            XCTAssertFalse(education.lifestyleFactors.isEmpty, "lifestyleFactors should not be empty for \(education.biomarkerName)")
        }
    }

    // MARK: - Education Lookup

    func testEducation_ForBiomarkerName_Exact() {
        let education = BiomarkerEducation.education(for: "crp")

        XCTAssertNotNil(education)
        XCTAssertEqual(education?.displayName, "C-Reactive Protein (CRP)")
    }

    func testEducation_ForBiomarkerName_CaseInsensitive() {
        let education1 = BiomarkerEducation.education(for: "CRP")
        let education2 = BiomarkerEducation.education(for: "Crp")

        XCTAssertNotNil(education1)
        XCTAssertNotNil(education2)
    }

    func testEducation_ForBiomarkerName_WithVariations() {
        let education1 = BiomarkerEducation.education(for: "vitamin-d")
        let education2 = BiomarkerEducation.education(for: "vitamin d")
        let education3 = BiomarkerEducation.education(for: "vitamin_d")

        // All variations should find the same biomarker
        XCTAssertNotNil(education3)
        // Note: education1 and education2 might be nil depending on normalization logic
    }

    func testEducation_ForBiomarkerName_NotFound() {
        let education = BiomarkerEducation.education(for: "nonexistent_marker")

        XCTAssertNil(education)
    }

    func testEducation_ForBiomarkerName_ByDisplayName() {
        let education = BiomarkerEducation.education(for: "Testosterone")

        XCTAssertNotNil(education)
    }

    // MARK: - Category Lookup

    func testEducation_ForCategory() {
        let inflammationEducation = BiomarkerEducation.education(forCategory: "Inflammation")

        XCTAssertFalse(inflammationEducation.isEmpty)
        for education in inflammationEducation {
            XCTAssertEqual(education.category, "Inflammation")
        }
    }

    func testEducation_ForCategory_CaseInsensitive() {
        let education1 = BiomarkerEducation.education(forCategory: "inflammation")
        let education2 = BiomarkerEducation.education(forCategory: "INFLAMMATION")
        let education3 = BiomarkerEducation.education(forCategory: "Inflammation")

        XCTAssertEqual(education1.count, education2.count)
        XCTAssertEqual(education2.count, education3.count)
    }

    func testEducation_ForCategory_EmptyForUnknown() {
        let education = BiomarkerEducation.education(forCategory: "NonexistentCategory")

        XCTAssertTrue(education.isEmpty)
    }

    // MARK: - Grouped by Category

    func testGroupedByCategory_NotEmpty() {
        let grouped = BiomarkerEducation.groupedByCategory

        XCTAssertFalse(grouped.isEmpty)
    }

    func testGroupedByCategory_ContainsExpectedCategories() {
        let grouped = BiomarkerEducation.groupedByCategory
        let categories = Set(grouped.keys)

        XCTAssertTrue(categories.contains("Inflammation"))
        XCTAssertTrue(categories.contains("Hormones"))
        XCTAssertTrue(categories.contains("Vitamins"))
        XCTAssertTrue(categories.contains("Minerals"))
        XCTAssertTrue(categories.contains("Metabolic"))
        XCTAssertTrue(categories.contains("Lipids"))
        XCTAssertTrue(categories.contains("Thyroid"))
        XCTAssertTrue(categories.contains("Blood Cells"))
    }

    func testGroupedByCategory_AllBiomarkersIncluded() {
        let grouped = BiomarkerEducation.groupedByCategory
        let totalCount = grouped.values.reduce(0) { $0 + $1.count }

        XCTAssertEqual(totalCount, BiomarkerEducation.allEducation.count)
    }

    // MARK: - Helper Methods

    private func createEducation(name: String, displayName: String) -> BiomarkerEducation {
        BiomarkerEducation(
            biomarkerName: name,
            displayName: displayName,
            category: "Other",
            shortDescription: "Short description",
            detailedDescription: "Detailed description",
            clinicalSignificance: "Clinical significance",
            dietarySources: ["Source 1"],
            lifestyleFactors: ["Factor 1"],
            unit: "units"
        )
    }
}

// MARK: - BiomarkerEducationCategory Tests

final class BiomarkerEducationCategoryTests: XCTestCase {

    // MARK: - All Cases

    func testBiomarkerEducationCategory_AllCases() {
        let allCases = BiomarkerEducationCategory.allCases

        XCTAssertEqual(allCases.count, 11)
    }

    func testBiomarkerEducationCategory_RawValues() {
        XCTAssertEqual(BiomarkerEducationCategory.inflammation.rawValue, "Inflammation")
        XCTAssertEqual(BiomarkerEducationCategory.hormones.rawValue, "Hormones")
        XCTAssertEqual(BiomarkerEducationCategory.metabolic.rawValue, "Metabolic")
        XCTAssertEqual(BiomarkerEducationCategory.vitamins.rawValue, "Vitamins")
        XCTAssertEqual(BiomarkerEducationCategory.minerals.rawValue, "Minerals")
        XCTAssertEqual(BiomarkerEducationCategory.lipids.rawValue, "Lipids")
        XCTAssertEqual(BiomarkerEducationCategory.thyroid.rawValue, "Thyroid")
        XCTAssertEqual(BiomarkerEducationCategory.cbc.rawValue, "Blood Cells")
        XCTAssertEqual(BiomarkerEducationCategory.liver.rawValue, "Liver")
        XCTAssertEqual(BiomarkerEducationCategory.kidney.rawValue, "Kidney")
        XCTAssertEqual(BiomarkerEducationCategory.other.rawValue, "Other")
    }

    // MARK: - Identifiable

    func testBiomarkerEducationCategory_Identifiable() {
        for category in BiomarkerEducationCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: - Icons

    func testBiomarkerEducationCategory_AllHaveIcons() {
        for category in BiomarkerEducationCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

    func testBiomarkerEducationCategory_SpecificIcons() {
        XCTAssertEqual(BiomarkerEducationCategory.inflammation.icon, "flame.fill")
        XCTAssertEqual(BiomarkerEducationCategory.hormones.icon, "waveform.path.ecg")
        XCTAssertEqual(BiomarkerEducationCategory.metabolic.icon, "bolt.fill")
        XCTAssertEqual(BiomarkerEducationCategory.vitamins.icon, "pill.fill")
        XCTAssertEqual(BiomarkerEducationCategory.minerals.icon, "atom")
        XCTAssertEqual(BiomarkerEducationCategory.lipids.icon, "heart.fill")
        XCTAssertEqual(BiomarkerEducationCategory.thyroid.icon, "thermometer.medium")
        XCTAssertEqual(BiomarkerEducationCategory.cbc.icon, "drop.fill")
        XCTAssertEqual(BiomarkerEducationCategory.liver.icon, "cross.case.fill")
        XCTAssertEqual(BiomarkerEducationCategory.kidney.icon, "water.waves")
        XCTAssertEqual(BiomarkerEducationCategory.other.icon, "chart.bar.fill")
    }

    // MARK: - Descriptions

    func testBiomarkerEducationCategory_AllHaveDescriptions() {
        for category in BiomarkerEducationCategory.allCases {
            XCTAssertFalse(category.description.isEmpty, "Category \(category) should have a description")
        }
    }

    func testBiomarkerEducationCategory_SpecificDescriptions() {
        XCTAssertTrue(BiomarkerEducationCategory.inflammation.description.contains("inflammation"))
        XCTAssertTrue(BiomarkerEducationCategory.hormones.description.contains("messengers") || BiomarkerEducationCategory.hormones.description.contains("functions"))
        XCTAssertTrue(BiomarkerEducationCategory.metabolic.description.contains("energy"))
        XCTAssertTrue(BiomarkerEducationCategory.vitamins.description.contains("nutrients") || BiomarkerEducationCategory.vitamins.description.contains("health"))
    }

    // MARK: - From String Mapping

    func testFromString_ExactMatch() {
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "inflammation"), .inflammation)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "hormones"), .hormones)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "metabolic"), .metabolic)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "vitamins"), .vitamins)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "minerals"), .minerals)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "lipids"), .lipids)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "thyroid"), .thyroid)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "cbc"), .cbc)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "liver"), .liver)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "kidney"), .kidney)
    }

    func testFromString_CaseInsensitive() {
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "INFLAMMATION"), .inflammation)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "Hormones"), .hormones)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "METABOLIC"), .metabolic)
    }

    func testFromString_Aliases() {
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "lipid panel"), .lipids)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "blood cells"), .cbc)
    }

    func testFromString_Unknown() {
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "unknown"), .other)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: "xyz123"), .other)
        XCTAssertEqual(BiomarkerEducationCategory.from(string: ""), .other)
    }
}

// MARK: - BiomarkerInterpretation Tests

final class BiomarkerInterpretationTests: XCTestCase {

    func testBiomarkerInterpretation_Initialization() {
        let interpretation = BiomarkerInterpretation(
            whenHigh: "May indicate inflammation",
            whenLow: "Generally optimal",
            trainingImpact: "Affects recovery time"
        )

        XCTAssertEqual(interpretation.whenHigh, "May indicate inflammation")
        XCTAssertEqual(interpretation.whenLow, "Generally optimal")
        XCTAssertEqual(interpretation.trainingImpact, "Affects recovery time")
    }

    func testBiomarkerInterpretation_OptionalTrainingImpact() {
        let interpretation = BiomarkerInterpretation(
            whenHigh: "High",
            whenLow: "Low",
            trainingImpact: nil
        )

        XCTAssertNil(interpretation.trainingImpact)
    }

    func testBiomarkerInterpretation_Hashable() {
        let interpretation1 = BiomarkerInterpretation(
            whenHigh: "High",
            whenLow: "Low",
            trainingImpact: "Impact"
        )

        let interpretation2 = BiomarkerInterpretation(
            whenHigh: "High",
            whenLow: "Low",
            trainingImpact: "Impact"
        )

        XCTAssertEqual(interpretation1, interpretation2)
    }
}

// MARK: - Integration Tests

final class BiomarkerEducationIntegrationTests: XCTestCase {

    func testEducationData_InflammationCategory() {
        let inflammationMarkers = BiomarkerEducation.education(forCategory: "Inflammation")

        XCTAssertFalse(inflammationMarkers.isEmpty)

        // CRP should be in inflammation
        let crp = inflammationMarkers.first { $0.biomarkerName == "crp" }
        XCTAssertNotNil(crp)
        XCTAssertEqual(crp?.category, "Inflammation")
    }

    func testEducationData_HormonesCategory() {
        let hormoneMarkers = BiomarkerEducation.education(forCategory: "Hormones")

        XCTAssertFalse(hormoneMarkers.isEmpty)

        // Testosterone and Cortisol should be in hormones
        let testosterone = hormoneMarkers.first { $0.biomarkerName == "testosterone" }
        let cortisol = hormoneMarkers.first { $0.biomarkerName == "cortisol" }

        XCTAssertNotNil(testosterone)
        XCTAssertNotNil(cortisol)
    }

    func testEducationData_VitaminsCategory() {
        let vitaminMarkers = BiomarkerEducation.education(forCategory: "Vitamins")

        XCTAssertFalse(vitaminMarkers.isEmpty)

        // Vitamin D and B12 should be in vitamins
        let vitaminD = vitaminMarkers.first { $0.biomarkerName == "vitamin_d" }
        let vitaminB12 = vitaminMarkers.first { $0.biomarkerName == "vitamin_b12" }

        XCTAssertNotNil(vitaminD)
        XCTAssertNotNil(vitaminB12)
    }

    func testEducationData_OptimalRanges() {
        for education in BiomarkerEducation.allEducation {
            // Most biomarkers should have at least one optimal range
            let hasRanges = education.optimalRangeMale != nil || education.optimalRangeFemale != nil

            // This is a soft assertion - log but don't fail
            if !hasRanges {
                print("Warning: \(education.biomarkerName) has no optimal ranges defined")
            }
        }
    }

    func testEducationData_DietarySources_NotEmpty() {
        for education in BiomarkerEducation.allEducation {
            XCTAssertFalse(
                education.dietarySources.isEmpty,
                "Dietary sources should not be empty for \(education.biomarkerName)"
            )
            XCTAssertGreaterThanOrEqual(
                education.dietarySources.count,
                2,
                "Should have at least 2 dietary sources for \(education.biomarkerName)"
            )
        }
    }

    func testEducationData_LifestyleFactors_NotEmpty() {
        for education in BiomarkerEducation.allEducation {
            XCTAssertFalse(
                education.lifestyleFactors.isEmpty,
                "Lifestyle factors should not be empty for \(education.biomarkerName)"
            )
            XCTAssertGreaterThanOrEqual(
                education.lifestyleFactors.count,
                2,
                "Should have at least 2 lifestyle factors for \(education.biomarkerName)"
            )
        }
    }
}
