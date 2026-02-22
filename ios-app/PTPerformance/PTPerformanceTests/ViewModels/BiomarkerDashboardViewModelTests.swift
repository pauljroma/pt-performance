//
//  BiomarkerDashboardViewModelTests.swift
//  PTPerformanceTests
//
//  Unit tests for BiomarkerDashboardViewModel
//  Tests initial state, category mapping, trend calculation,
//  status determination, computed properties, and score/delta calculations
//

import XCTest
@testable import PTPerformance

// MARK: - Biomarker Dashboard ViewModel Tests

@MainActor
final class BiomarkerDashboardViewModelTests: XCTestCase {

    var sut: BiomarkerDashboardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = BiomarkerDashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_BiomarkerSummariesIsEmpty() {
        XCTAssertTrue(sut.biomarkerSummaries.isEmpty, "biomarkerSummaries should be empty initially")
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }

    func testInitialState_ErrorIsNil() {
        XCTAssertNil(sut.error, "error should be nil initially")
    }

    func testInitialState_SelectedCategoryIsNil() {
        XCTAssertNil(sut.selectedCategory, "selectedCategory should be nil initially")
    }

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "", "searchText should be empty initially")
    }

    func testInitialState_TrainingImpactsIsEmpty() {
        XCTAssertTrue(sut.trainingImpacts.isEmpty, "trainingImpacts should be empty initially")
    }

    func testInitialState_CategoryStatusesIsEmpty() {
        XCTAssertTrue(sut.categoryStatuses.isEmpty, "categoryStatuses should be empty initially")
    }

    func testInitialState_SelectedBiomarkerIsNil() {
        XCTAssertNil(sut.selectedBiomarker, "selectedBiomarker should be nil initially")
    }

    func testInitialState_BiomarkerHistoryIsEmpty() {
        XCTAssertTrue(sut.biomarkerHistory.isEmpty, "biomarkerHistory should be empty initially")
    }

    func testInitialState_IsLoadingHistoryIsFalse() {
        XCTAssertFalse(sut.isLoadingHistory, "isLoadingHistory should be false initially")
    }

    // MARK: - Published Properties Settable Tests

    func testPublishedProperties_IsLoadingCanBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading, "isLoading should be settable to true")
    }

    func testPublishedProperties_ErrorCanBeSet() {
        sut.error = "Network error"
        XCTAssertEqual(sut.error, "Network error")
    }

    func testPublishedProperties_SearchTextCanBeSet() {
        sut.searchText = "vitamin"
        XCTAssertEqual(sut.searchText, "vitamin")
    }

    func testPublishedProperties_SelectedCategoryCanBeSet() {
        sut.selectedCategory = .hormones
        XCTAssertEqual(sut.selectedCategory, .hormones)

        sut.selectedCategory = nil
        XCTAssertNil(sut.selectedCategory)
    }

    // MARK: - BiomarkerCategory Mapping Tests

    func testCategoryMapping_Inflammation_CRP() {
        XCTAssertEqual(BiomarkerCategory.category(for: "CRP"), .inflammation)
    }

    func testCategoryMapping_Inflammation_CReactiveProtein() {
        XCTAssertEqual(BiomarkerCategory.category(for: "C-Reactive Protein"), .inflammation)
    }

    func testCategoryMapping_Inflammation_ESR() {
        XCTAssertEqual(BiomarkerCategory.category(for: "ESR"), .inflammation)
    }

    func testCategoryMapping_Inflammation_SedRate() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Sed Rate"), .inflammation)
    }

    func testCategoryMapping_Inflammation_Homocysteine() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Homocysteine"), .inflammation)
    }

    func testCategoryMapping_Inflammation_Fibrinogen() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Fibrinogen"), .inflammation)
    }

    func testCategoryMapping_Inflammation_Interleukin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Interleukin-6"), .inflammation)
    }

    func testCategoryMapping_Inflammation_TNF() {
        XCTAssertEqual(BiomarkerCategory.category(for: "TNF-alpha"), .inflammation)
    }

    func testCategoryMapping_Hormones_Testosterone() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Testosterone"), .hormones)
    }

    func testCategoryMapping_Hormones_Estrogen() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Estrogen"), .hormones)
    }

    func testCategoryMapping_Hormones_Estradiol() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Estradiol"), .hormones)
    }

    func testCategoryMapping_Hormones_Cortisol() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Cortisol"), .hormones)
    }

    func testCategoryMapping_Hormones_DHEA() {
        XCTAssertEqual(BiomarkerCategory.category(for: "DHEA-S"), .hormones)
    }

    func testCategoryMapping_Hormones_Progesterone() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Progesterone"), .hormones)
    }

    func testCategoryMapping_Hormones_SHBG() {
        XCTAssertEqual(BiomarkerCategory.category(for: "SHBG"), .hormones)
    }

    func testCategoryMapping_Hormones_FSH() {
        XCTAssertEqual(BiomarkerCategory.category(for: "FSH"), .hormones)
    }

    func testCategoryMapping_Hormones_LH() {
        XCTAssertEqual(BiomarkerCategory.category(for: "LH"), .hormones)
    }

    func testCategoryMapping_Hormones_Prolactin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Prolactin"), .hormones)
    }

    func testCategoryMapping_Hormones_IGF() {
        XCTAssertEqual(BiomarkerCategory.category(for: "IGF-1"), .hormones)
    }

    func testCategoryMapping_Hormones_GrowthHormone() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Growth Hormone"), .hormones)
    }

    func testCategoryMapping_Metabolic_Glucose() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Glucose"), .metabolic)
    }

    func testCategoryMapping_Metabolic_Insulin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Insulin"), .metabolic)
    }

    func testCategoryMapping_Metabolic_A1c() {
        XCTAssertEqual(BiomarkerCategory.category(for: "A1c"), .metabolic)
    }

    func testCategoryMapping_Metabolic_HemoglobinA1c() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Hemoglobin A1c"), .metabolic)
    }

    func testCategoryMapping_Metabolic_HbA1c() {
        XCTAssertEqual(BiomarkerCategory.category(for: "HbA1c"), .metabolic)
    }

    func testCategoryMapping_Metabolic_FastingGlucose() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Fasting Glucose"), .metabolic)
    }

    func testCategoryMapping_Vitamins_VitaminD() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Vitamin D"), .vitamins)
    }

    func testCategoryMapping_Vitamins_B12() {
        XCTAssertEqual(BiomarkerCategory.category(for: "B12"), .vitamins)
    }

    func testCategoryMapping_Vitamins_Folate() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Folate"), .vitamins)
    }

    func testCategoryMapping_Vitamins_D3() {
        XCTAssertEqual(BiomarkerCategory.category(for: "D3"), .vitamins)
    }

    func testCategoryMapping_Vitamins_Thiamine() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Thiamine"), .vitamins)
    }

    func testCategoryMapping_Vitamins_Riboflavin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Riboflavin"), .vitamins)
    }

    func testCategoryMapping_Vitamins_Niacin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Niacin"), .vitamins)
    }

    func testCategoryMapping_Minerals_Iron() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Iron"), .minerals)
    }

    func testCategoryMapping_Minerals_Ferritin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Ferritin"), .minerals)
    }

    func testCategoryMapping_Minerals_TIBC() {
        XCTAssertEqual(BiomarkerCategory.category(for: "TIBC"), .minerals)
    }

    func testCategoryMapping_Minerals_Zinc() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Zinc"), .minerals)
    }

    func testCategoryMapping_Minerals_Magnesium() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Magnesium"), .minerals)
    }

    func testCategoryMapping_Minerals_Calcium() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Calcium"), .minerals)
    }

    func testCategoryMapping_Minerals_Potassium() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Potassium"), .minerals)
    }

    func testCategoryMapping_Minerals_Sodium() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Sodium"), .minerals)
    }

    func testCategoryMapping_Minerals_Phosphorus() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Phosphorus"), .minerals)
    }

    func testCategoryMapping_Minerals_Copper() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Copper"), .minerals)
    }

    func testCategoryMapping_Minerals_Selenium() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Selenium"), .minerals)
    }

    func testCategoryMapping_LipidPanel_Cholesterol() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Cholesterol"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_LDL() {
        XCTAssertEqual(BiomarkerCategory.category(for: "LDL"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_HDL() {
        XCTAssertEqual(BiomarkerCategory.category(for: "HDL"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_Triglycerides() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Triglycerides"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_VLDL() {
        XCTAssertEqual(BiomarkerCategory.category(for: "VLDL"), .lipidPanel)
    }

    func testCategoryMapping_LipidPanel_Apolipoprotein() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Apolipoprotein B"), .lipidPanel)
    }

    func testCategoryMapping_Thyroid_TSH() {
        XCTAssertEqual(BiomarkerCategory.category(for: "TSH"), .thyroid)
    }

    func testCategoryMapping_Thyroid_T3() {
        XCTAssertEqual(BiomarkerCategory.category(for: "T3"), .thyroid)
    }

    func testCategoryMapping_Thyroid_T4() {
        XCTAssertEqual(BiomarkerCategory.category(for: "T4"), .thyroid)
    }

    func testCategoryMapping_Thyroid_Thyroxine() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Thyroxine"), .thyroid)
    }

    func testCategoryMapping_CBC_RBC() {
        XCTAssertEqual(BiomarkerCategory.category(for: "RBC"), .cbc)
    }

    func testCategoryMapping_CBC_WBC() {
        XCTAssertEqual(BiomarkerCategory.category(for: "WBC"), .cbc)
    }

    func testCategoryMapping_CBC_Hemoglobin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Hemoglobin"), .cbc)
    }

    func testCategoryMapping_CBC_Hematocrit() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Hematocrit"), .cbc)
    }

    func testCategoryMapping_CBC_Platelet() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Platelet Count"), .cbc)
    }

    func testCategoryMapping_CBC_MCV() {
        XCTAssertEqual(BiomarkerCategory.category(for: "MCV"), .cbc)
    }

    func testCategoryMapping_CBC_MCH() {
        XCTAssertEqual(BiomarkerCategory.category(for: "MCH"), .cbc)
    }

    func testCategoryMapping_CBC_MCHC() {
        XCTAssertEqual(BiomarkerCategory.category(for: "MCHC"), .cbc)
    }

    func testCategoryMapping_CBC_RDW() {
        XCTAssertEqual(BiomarkerCategory.category(for: "RDW"), .cbc)
    }

    func testCategoryMapping_CBC_Neutrophil() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Neutrophil Count"), .cbc)
    }

    func testCategoryMapping_CBC_Lymphocyte() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Lymphocyte"), .cbc)
    }

    func testCategoryMapping_CBC_Monocyte() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Monocyte"), .cbc)
    }

    func testCategoryMapping_CBC_Eosinophil() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Eosinophil"), .cbc)
    }

    func testCategoryMapping_CBC_Basophil() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Basophil"), .cbc)
    }

    func testCategoryMapping_Liver_ALT() {
        XCTAssertEqual(BiomarkerCategory.category(for: "ALT"), .liver)
    }

    func testCategoryMapping_Liver_AST() {
        XCTAssertEqual(BiomarkerCategory.category(for: "AST"), .liver)
    }

    func testCategoryMapping_Liver_ALP() {
        XCTAssertEqual(BiomarkerCategory.category(for: "ALP"), .liver)
    }

    func testCategoryMapping_Liver_Bilirubin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Bilirubin"), .liver)
    }

    func testCategoryMapping_Liver_Albumin() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Albumin"), .liver)
    }

    func testCategoryMapping_Liver_GGT() {
        XCTAssertEqual(BiomarkerCategory.category(for: "GGT"), .liver)
    }

    func testCategoryMapping_Kidney_Creatinine() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Creatinine"), .kidney)
    }

    func testCategoryMapping_Kidney_BUN() {
        XCTAssertEqual(BiomarkerCategory.category(for: "BUN"), .kidney)
    }

    func testCategoryMapping_Kidney_Urea() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Urea"), .kidney)
    }

    func testCategoryMapping_Kidney_eGFR() {
        XCTAssertEqual(BiomarkerCategory.category(for: "eGFR"), .kidney)
    }

    func testCategoryMapping_Kidney_UricAcid() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Uric Acid"), .kidney)
    }

    func testCategoryMapping_Other_UnknownMarker() {
        XCTAssertEqual(BiomarkerCategory.category(for: "Some Random Biomarker"), .other)
    }

    func testCategoryMapping_CaseInsensitive() {
        XCTAssertEqual(BiomarkerCategory.category(for: "crp"), .inflammation)
        XCTAssertEqual(BiomarkerCategory.category(for: "TESTOSTERONE"), .hormones)
        XCTAssertEqual(BiomarkerCategory.category(for: "glucose"), .metabolic)
        XCTAssertEqual(BiomarkerCategory.category(for: "VITAMIN D"), .vitamins)
        XCTAssertEqual(BiomarkerCategory.category(for: "iron"), .minerals)
        XCTAssertEqual(BiomarkerCategory.category(for: "cholesterol"), .lipidPanel)
        XCTAssertEqual(BiomarkerCategory.category(for: "TSH"), .thyroid)
        XCTAssertEqual(BiomarkerCategory.category(for: "rbc"), .cbc)
        XCTAssertEqual(BiomarkerCategory.category(for: "ALT"), .liver)
        XCTAssertEqual(BiomarkerCategory.category(for: "creatinine"), .kidney)
    }

    // MARK: - BiomarkerCategory Properties Tests

    func testBiomarkerCategory_AllCasesCount() {
        XCTAssertEqual(BiomarkerCategory.allCases.count, 11, "Should have 11 biomarker categories")
    }

    func testBiomarkerCategory_IdentifiableById() {
        for category in BiomarkerCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue,
                           "id should equal rawValue for \(category)")
        }
    }

    func testBiomarkerCategory_RawValues() {
        XCTAssertEqual(BiomarkerCategory.inflammation.rawValue, "Inflammation")
        XCTAssertEqual(BiomarkerCategory.hormones.rawValue, "Hormones")
        XCTAssertEqual(BiomarkerCategory.metabolic.rawValue, "Metabolic")
        XCTAssertEqual(BiomarkerCategory.vitamins.rawValue, "Vitamins")
        XCTAssertEqual(BiomarkerCategory.minerals.rawValue, "Minerals")
        XCTAssertEqual(BiomarkerCategory.lipidPanel.rawValue, "Lipids")
        XCTAssertEqual(BiomarkerCategory.thyroid.rawValue, "Thyroid")
        XCTAssertEqual(BiomarkerCategory.cbc.rawValue, "CBC")
        XCTAssertEqual(BiomarkerCategory.liver.rawValue, "Liver")
        XCTAssertEqual(BiomarkerCategory.kidney.rawValue, "Kidney")
        XCTAssertEqual(BiomarkerCategory.other.rawValue, "Other")
    }

    func testBiomarkerCategory_IconsNotEmpty() {
        for category in BiomarkerCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty,
                           "icon should not be empty for \(category)")
        }
    }

    func testBiomarkerCategory_TrainingExplanationsNotEmpty() {
        for category in BiomarkerCategory.allCases {
            XCTAssertFalse(category.trainingExplanation.isEmpty,
                           "trainingExplanation should not be empty for \(category)")
        }
    }

    // MARK: - BiomarkerTrend Tests

    func testBiomarkerTrend_RawValues() {
        XCTAssertEqual(BiomarkerTrend.increasing.rawValue, "increasing")
        XCTAssertEqual(BiomarkerTrend.decreasing.rawValue, "decreasing")
        XCTAssertEqual(BiomarkerTrend.stable.rawValue, "stable")
        XCTAssertEqual(BiomarkerTrend.unknown.rawValue, "unknown")
    }

    func testBiomarkerTrend_Icons() {
        XCTAssertEqual(BiomarkerTrend.increasing.icon, "arrow.up")
        XCTAssertEqual(BiomarkerTrend.decreasing.icon, "arrow.down")
        XCTAssertEqual(BiomarkerTrend.stable.icon, "arrow.forward")
        XCTAssertEqual(BiomarkerTrend.unknown.icon, "minus")
    }

    func testBiomarkerTrend_AccessibilityLabels() {
        XCTAssertEqual(BiomarkerTrend.increasing.accessibilityLabel, "trending up")
        XCTAssertEqual(BiomarkerTrend.decreasing.accessibilityLabel, "trending down")
        XCTAssertEqual(BiomarkerTrend.stable.accessibilityLabel, "stable")
        XCTAssertEqual(BiomarkerTrend.unknown.accessibilityLabel, "trend unknown")
    }

    // MARK: - TrainingImpactSeverity Tests

    func testTrainingImpactSeverity_RawValues() {
        XCTAssertEqual(TrainingImpactSeverity.info.rawValue, "info")
        XCTAssertEqual(TrainingImpactSeverity.moderate.rawValue, "moderate")
        XCTAssertEqual(TrainingImpactSeverity.significant.rawValue, "significant")
    }

    func testTrainingImpactSeverity_AllCasesCount() {
        XCTAssertEqual(TrainingImpactSeverity.allCases.count, 3)
    }

    func testTrainingImpactSeverity_Icons() {
        XCTAssertEqual(TrainingImpactSeverity.info.icon, "lightbulb.fill")
        XCTAssertEqual(TrainingImpactSeverity.moderate.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(TrainingImpactSeverity.significant.icon, "exclamationmark.octagon.fill")
    }

    // MARK: - SystemStatusLevel Tests

    func testSystemStatusLevel_RawValues() {
        XCTAssertEqual(SystemStatusLevel.optimal.rawValue, "optimal")
        XCTAssertEqual(SystemStatusLevel.attention.rawValue, "attention")
        XCTAssertEqual(SystemStatusLevel.critical.rawValue, "critical")
    }

    func testSystemStatusLevel_DisplayText() {
        XCTAssertEqual(SystemStatusLevel.optimal.displayText, "Optimal")
        XCTAssertEqual(SystemStatusLevel.attention.displayText, "Attention")
        XCTAssertEqual(SystemStatusLevel.critical.displayText, "Critical")
    }

    func testSystemStatusLevel_AllCasesCount() {
        XCTAssertEqual(SystemStatusLevel.allCases.count, 3)
    }

    func testSystemStatusLevel_Emojis() {
        XCTAssertEqual(SystemStatusLevel.optimal.emoji, "checkmark.circle.fill")
        XCTAssertEqual(SystemStatusLevel.attention.emoji, "exclamationmark.triangle.fill")
        XCTAssertEqual(SystemStatusLevel.critical.emoji, "xmark.circle.fill")
    }

    // MARK: - BiomarkerSummary formattedValue Tests

    func testFormattedValue_LargeValue_NoDecimalPlaces() {
        let summary = makeSummary(currentValue: 1500.0)
        XCTAssertEqual(summary.formattedValue, "1500", "Values >= 1000 should have no decimal places")
    }

    func testFormattedValue_ExactThousand() {
        let summary = makeSummary(currentValue: 1000.0)
        XCTAssertEqual(summary.formattedValue, "1000")
    }

    func testFormattedValue_HundredsRange_OneDecimalPlace() {
        let summary = makeSummary(currentValue: 250.5)
        XCTAssertEqual(summary.formattedValue, "250.5", "Values 100-999 should have 1 decimal place")
    }

    func testFormattedValue_TensRange_OneDecimalPlace() {
        let summary = makeSummary(currentValue: 45.3)
        XCTAssertEqual(summary.formattedValue, "45.3", "Values 10-99 should have 1 decimal place")
    }

    func testFormattedValue_SmallValue_TwoDecimalPlaces() {
        let summary = makeSummary(currentValue: 3.14)
        XCTAssertEqual(summary.formattedValue, "3.14", "Values < 10 should have 2 decimal places")
    }

    func testFormattedValue_VerySmallValue() {
        let summary = makeSummary(currentValue: 0.75)
        XCTAssertEqual(summary.formattedValue, "0.75")
    }

    func testFormattedValue_Zero() {
        let summary = makeSummary(currentValue: 0.0)
        XCTAssertEqual(summary.formattedValue, "0.00")
    }

    func testFormattedValue_BoundaryAt100() {
        let summary = makeSummary(currentValue: 100.0)
        XCTAssertEqual(summary.formattedValue, "100.0")
    }

    func testFormattedValue_BoundaryAt10() {
        let summary = makeSummary(currentValue: 10.0)
        XCTAssertEqual(summary.formattedValue, "10.0")
    }

    // MARK: - BiomarkerSummary DisplayName Tests

    func testBiomarkerSummary_DefaultDisplayName() {
        let summary = BiomarkerSummary(
            name: "testosterone",
            category: .hormones,
            currentValue: 500.0,
            unit: "ng/dL",
            status: .optimal,
            lastUpdated: TestDates.reference
        )
        XCTAssertEqual(summary.displayName, "testosterone",
                       "displayName should default to name when not provided")
    }

    func testBiomarkerSummary_CustomDisplayName() {
        let summary = BiomarkerSummary(
            name: "crp",
            displayName: "C-Reactive Protein",
            category: .inflammation,
            currentValue: 1.2,
            unit: "mg/L",
            status: .normal,
            lastUpdated: TestDates.reference
        )
        XCTAssertEqual(summary.displayName, "C-Reactive Protein")
    }

    // MARK: - Computed Properties: filteredBiomarkers Tests

    func testFilteredBiomarkers_WhenNoFilterApplied_ReturnsAll() {
        sut.biomarkerSummaries = makeSummaries()
        XCTAssertEqual(sut.filteredBiomarkers.count, sut.biomarkerSummaries.count,
                       "Should return all biomarkers when no filter is applied")
    }

    func testFilteredBiomarkers_WhenCategorySelected_FiltersCorrectly() {
        sut.biomarkerSummaries = makeSummaries()
        sut.selectedCategory = .inflammation

        let filtered = sut.filteredBiomarkers
        XCTAssertTrue(filtered.allSatisfy { $0.category == .inflammation },
                      "All filtered results should have inflammation category")
    }

    func testFilteredBiomarkers_WhenSearchTextApplied_FiltersByName() {
        sut.biomarkerSummaries = makeSummaries()
        sut.searchText = "Testosterone"

        let filtered = sut.filteredBiomarkers
        XCTAssertTrue(filtered.allSatisfy {
            $0.name.lowercased().contains("testosterone") ||
            $0.displayName.lowercased().contains("testosterone")
        }, "All filtered results should match search text")
    }

    func testFilteredBiomarkers_SearchIsCaseInsensitive() {
        sut.biomarkerSummaries = makeSummaries()
        sut.searchText = "crp"

        let filtered = sut.filteredBiomarkers
        XCTAssertFalse(filtered.isEmpty, "Search should be case insensitive")
    }

    func testFilteredBiomarkers_WhenBothFiltersApplied() {
        sut.biomarkerSummaries = makeSummaries()
        sut.selectedCategory = .hormones
        sut.searchText = "Testosterone"

        let filtered = sut.filteredBiomarkers
        XCTAssertTrue(filtered.allSatisfy {
            $0.category == .hormones &&
            ($0.name.lowercased().contains("testosterone") ||
             $0.displayName.lowercased().contains("testosterone"))
        })
    }

    func testFilteredBiomarkers_WhenSearchMatchesNothing_ReturnsEmpty() {
        sut.biomarkerSummaries = makeSummaries()
        sut.searchText = "zzzznonexistent"

        XCTAssertTrue(sut.filteredBiomarkers.isEmpty,
                      "Should return empty when search matches nothing")
    }

    // MARK: - Computed Properties: groupedBiomarkers Tests

    func testGroupedBiomarkers_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.groupedBiomarkers.isEmpty)
    }

    func testGroupedBiomarkers_GroupsByCategory() {
        sut.biomarkerSummaries = makeSummaries()

        let grouped = sut.groupedBiomarkers
        XCTAssertFalse(grouped.isEmpty)

        // Each biomarker should be in its correct category group
        for (category, summaries) in grouped {
            XCTAssertTrue(summaries.allSatisfy { $0.category == category },
                          "All summaries in group \(category) should have that category")
        }
    }

    // MARK: - Computed Properties: categoriesWithBiomarkers Tests

    func testCategoriesWithBiomarkers_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.categoriesWithBiomarkers.isEmpty)
    }

    func testCategoriesWithBiomarkers_ReturnsOnlyCategoriesWithData() {
        sut.biomarkerSummaries = [
            makeSummary(name: "CRP", category: .inflammation),
            makeSummary(name: "Testosterone", category: .hormones)
        ]

        let categories = sut.categoriesWithBiomarkers
        XCTAssertTrue(categories.contains(.inflammation))
        XCTAssertTrue(categories.contains(.hormones))
        XCTAssertFalse(categories.contains(.metabolic))
    }

    func testCategoriesWithBiomarkers_MaintainsCaseOrder() {
        sut.biomarkerSummaries = [
            makeSummary(name: "Creatinine", category: .kidney),
            makeSummary(name: "CRP", category: .inflammation),
            makeSummary(name: "Testosterone", category: .hormones)
        ]

        let categories = sut.categoriesWithBiomarkers
        // Should follow BiomarkerCategory.allCases ordering
        let allCasesOrder = BiomarkerCategory.allCases
        var lastIndex = -1
        for cat in categories {
            if let idx = allCasesOrder.firstIndex(of: cat) {
                XCTAssertGreaterThan(idx, lastIndex,
                                     "Categories should maintain allCases order")
                lastIndex = idx
            }
        }
    }

    // MARK: - Computed Properties: statusCounts Tests

    func testStatusCounts_WhenEmpty_AllZero() {
        let counts = sut.statusCounts
        XCTAssertEqual(counts.optimal, 0)
        XCTAssertEqual(counts.normal, 0)
        XCTAssertEqual(counts.concern, 0)
    }

    func testStatusCounts_CorrectlyCategorizes() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .optimal),
            makeSummary(name: "B", status: .optimal),
            makeSummary(name: "C", status: .normal),
            makeSummary(name: "D", status: .low),
            makeSummary(name: "E", status: .high),
            makeSummary(name: "F", status: .critical)
        ]

        let counts = sut.statusCounts
        XCTAssertEqual(counts.optimal, 2, "Should have 2 optimal")
        XCTAssertEqual(counts.normal, 1, "Should have 1 normal")
        XCTAssertEqual(counts.concern, 3, "Should have 3 concern (low + high + critical)")
    }

    func testStatusCounts_AllOptimal() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .optimal),
            makeSummary(name: "B", status: .optimal)
        ]

        let counts = sut.statusCounts
        XCTAssertEqual(counts.optimal, 2)
        XCTAssertEqual(counts.normal, 0)
        XCTAssertEqual(counts.concern, 0)
    }

    // MARK: - Computed Properties: concerningBiomarkers Tests

    func testConcerningBiomarkers_WhenEmpty_ReturnsEmpty() {
        XCTAssertTrue(sut.concerningBiomarkers.isEmpty)
    }

    func testConcerningBiomarkers_IncludesLowHighCritical() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .optimal),
            makeSummary(name: "B", status: .normal),
            makeSummary(name: "C", status: .low),
            makeSummary(name: "D", status: .high),
            makeSummary(name: "E", status: .critical)
        ]

        let concerning = sut.concerningBiomarkers
        XCTAssertEqual(concerning.count, 3, "Should have 3 concerning (low, high, critical)")
        XCTAssertTrue(concerning.contains { $0.name == "C" })
        XCTAssertTrue(concerning.contains { $0.name == "D" })
        XCTAssertTrue(concerning.contains { $0.name == "E" })
    }

    func testConcerningBiomarkers_ExcludesOptimalAndNormal() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .optimal),
            makeSummary(name: "B", status: .normal)
        ]

        XCTAssertTrue(sut.concerningBiomarkers.isEmpty,
                      "Should not include optimal or normal biomarkers")
    }

    // MARK: - Computed Properties: lastLabDate Tests

    func testLastLabDate_WhenEmpty_ReturnsNil() {
        XCTAssertNil(sut.lastLabDate)
    }

    func testLastLabDate_ReturnsMostRecent() {
        let oldest = TestDates.daysFromReference(-10)
        let middle = TestDates.daysFromReference(-5)
        let newest = TestDates.daysFromReference(0)

        sut.biomarkerSummaries = [
            makeSummary(name: "A", lastUpdated: oldest),
            makeSummary(name: "B", lastUpdated: newest),
            makeSummary(name: "C", lastUpdated: middle)
        ]

        XCTAssertEqual(sut.lastLabDate, newest, "Should return the most recent date")
    }

    // MARK: - Computed Properties: daysSinceLastLab Tests

    func testDaysSinceLastLab_WhenEmpty_ReturnsNil() {
        XCTAssertNil(sut.daysSinceLastLab)
    }

    func testDaysSinceLastLab_ReturnsCorrectDayCount() {
        let threeDaysAgo = TestDates.daysFromNow(-3)
        sut.biomarkerSummaries = [
            makeSummary(name: "A", lastUpdated: threeDaysAgo)
        ]

        if let days = sut.daysSinceLastLab {
            XCTAssertEqual(days, 3, "Should return 3 days since last lab")
        } else {
            XCTFail("daysSinceLastLab should not be nil")
        }
    }

    // MARK: - Computed Properties: statusSummaryText Tests

    func testStatusSummaryText_WhenEmpty_ReturnsEmptyString() {
        XCTAssertEqual(sut.statusSummaryText, "", "Should be empty when no biomarkers")
    }

    func testStatusSummaryText_OnlyConcern_SingleMarker() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .high)
        ]

        XCTAssertEqual(sut.statusSummaryText, "1 marker needs attention")
    }

    func testStatusSummaryText_MultipleConcerns() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .high),
            makeSummary(name: "B", status: .low),
            makeSummary(name: "C", status: .critical)
        ]

        XCTAssertTrue(sut.statusSummaryText.contains("3 markers need attention"))
    }

    func testStatusSummaryText_OnlyOptimal_SingleMarker() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .optimal)
        ]

        XCTAssertEqual(sut.statusSummaryText, "1 marker optimal")
    }

    func testStatusSummaryText_MixedConcernAndOptimal() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .high),
            makeSummary(name: "B", status: .optimal),
            makeSummary(name: "C", status: .optimal)
        ]

        let text = sut.statusSummaryText
        XCTAssertTrue(text.contains("1 marker needs attention"), "Should mention concern")
        XCTAssertTrue(text.contains("2 markers optimal"), "Should mention optimal count")
        XCTAssertTrue(text.contains(" | "), "Parts should be separated by pipe")
    }

    func testStatusSummaryText_OnlyNormal_NoText() {
        sut.biomarkerSummaries = [
            makeSummary(name: "A", status: .normal)
        ]

        XCTAssertEqual(sut.statusSummaryText, "",
                       "Normal markers do not produce summary text since they are neither concern nor optimal")
    }

    // MARK: - Computed Properties: primaryTrainingImpact Tests

    func testPrimaryTrainingImpact_WhenEmpty_ReturnsNil() {
        XCTAssertNil(sut.primaryTrainingImpact)
    }

    func testPrimaryTrainingImpact_PrioritizesSignificant() {
        let info = TrainingImpact(
            biomarkerName: "B12", insight: "Low", recommendations: [], severity: .info
        )
        let moderate = TrainingImpact(
            biomarkerName: "Iron", insight: "Low", recommendations: [], severity: .moderate
        )
        let significant = TrainingImpact(
            biomarkerName: "Cortisol", insight: "High", recommendations: [], severity: .significant
        )

        sut.trainingImpacts = [info, moderate, significant]

        XCTAssertEqual(sut.primaryTrainingImpact?.severity, .significant,
                       "Should prioritize significant impacts")
    }

    func testPrimaryTrainingImpact_FallsBackToModerate() {
        let info = TrainingImpact(
            biomarkerName: "B12", insight: "Low", recommendations: [], severity: .info
        )
        let moderate = TrainingImpact(
            biomarkerName: "Iron", insight: "Low", recommendations: [], severity: .moderate
        )

        sut.trainingImpacts = [info, moderate]

        XCTAssertEqual(sut.primaryTrainingImpact?.severity, .moderate,
                       "Should fall back to moderate when no significant")
    }

    func testPrimaryTrainingImpact_FallsBackToInfo() {
        let info = TrainingImpact(
            biomarkerName: "B12", insight: "Low", recommendations: [], severity: .info
        )

        sut.trainingImpacts = [info]

        XCTAssertEqual(sut.primaryTrainingImpact?.severity, .info,
                       "Should fall back to info when no significant or moderate")
    }

    // MARK: - Computed Properties: hasTrainingImpacts Tests

    func testHasTrainingImpacts_WhenEmpty_ReturnsFalse() {
        XCTAssertFalse(sut.hasTrainingImpacts)
    }

    func testHasTrainingImpacts_WhenNotEmpty_ReturnsTrue() {
        sut.trainingImpacts = [
            TrainingImpact(biomarkerName: "CRP", insight: "Elevated", recommendations: ["Rest"], severity: .moderate)
        ]
        XCTAssertTrue(sut.hasTrainingImpacts)
    }

    // MARK: - clearSelection Tests

    func testClearSelection_ResetsSelectedBiomarkerAndHistory() {
        let summary = makeSummary(name: "Testosterone")
        sut.selectedBiomarker = summary
        sut.biomarkerHistory = [
            BiomarkerTrendPoint(
                id: UUID(), date: Date(), value: 500.0,
                biomarkerType: "Testosterone", unit: "ng/dL",
                optimalLow: nil, optimalHigh: nil,
                normalLow: 300.0, normalHigh: 1000.0
            )
        ]

        sut.clearSelection()

        XCTAssertNil(sut.selectedBiomarker, "selectedBiomarker should be nil after clearing")
        XCTAssertTrue(sut.biomarkerHistory.isEmpty, "biomarkerHistory should be empty after clearing")
    }

    // MARK: - dismissTrainingImpact Tests

    func testDismissTrainingImpact_RemovesMatchingImpact() {
        let impact1 = TrainingImpact(
            biomarkerName: "CRP", insight: "High", recommendations: [], severity: .moderate
        )
        let impact2 = TrainingImpact(
            biomarkerName: "Cortisol", insight: "High", recommendations: [], severity: .significant
        )

        sut.trainingImpacts = [impact1, impact2]
        sut.dismissTrainingImpact(impact1)

        XCTAssertEqual(sut.trainingImpacts.count, 1, "Should have 1 impact after dismissal")
        XCTAssertEqual(sut.trainingImpacts.first?.biomarkerName, "Cortisol",
                       "Remaining impact should be Cortisol")
    }

    func testDismissTrainingImpact_WhenLastImpact_LeavesEmpty() {
        let impact = TrainingImpact(
            biomarkerName: "CRP", insight: "High", recommendations: [], severity: .moderate
        )

        sut.trainingImpacts = [impact]
        sut.dismissTrainingImpact(impact)

        XCTAssertTrue(sut.trainingImpacts.isEmpty)
        XCTAssertFalse(sut.hasTrainingImpacts)
    }

    // MARK: - systemStatus(for:) Tests

    func testSystemStatus_ReturnsCorrectStatus() {
        let status = CategorySystemStatus(
            category: .inflammation,
            status: .attention,
            optimalCount: 1,
            attentionCount: 1,
            criticalCount: 0,
            totalCount: 2
        )

        sut.categoryStatuses = [status]

        let result = sut.systemStatus(for: .inflammation)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.category, .inflammation)
        XCTAssertEqual(result?.status, .attention)
    }

    func testSystemStatus_ReturnsNilForMissingCategory() {
        sut.categoryStatuses = [
            CategorySystemStatus(
                category: .inflammation,
                status: .optimal,
                optimalCount: 2,
                attentionCount: 0,
                criticalCount: 0,
                totalCount: 2
            )
        ]

        XCTAssertNil(sut.systemStatus(for: .hormones),
                     "Should return nil for a category not in statuses")
    }

    // MARK: - TrainingImpact Model Tests

    func testTrainingImpact_Equatable() {
        let id = UUID()
        let impact1 = TrainingImpact(
            id: id, biomarkerName: "CRP", insight: "High",
            recommendations: ["Rest"], severity: .moderate
        )
        let impact2 = TrainingImpact(
            id: id, biomarkerName: "CRP", insight: "High",
            recommendations: ["Rest"], severity: .moderate
        )

        XCTAssertEqual(impact1, impact2)
    }

    func testTrainingImpact_DefaultActionButtonTitleIsNil() {
        let impact = TrainingImpact(
            biomarkerName: "CRP", insight: "High",
            recommendations: ["Rest"], severity: .moderate
        )
        XCTAssertNil(impact.actionButtonTitle)
    }

    func testTrainingImpact_CustomActionButtonTitle() {
        let impact = TrainingImpact(
            biomarkerName: "CRP", insight: "High",
            recommendations: ["Rest"], severity: .moderate,
            actionButtonTitle: "Adjust Program"
        )
        XCTAssertEqual(impact.actionButtonTitle, "Adjust Program")
    }

    // MARK: - CategorySystemStatus Model Tests

    func testCategorySystemStatus_Equatable() {
        let id = UUID()
        let status1 = CategorySystemStatus(
            id: id, category: .hormones, status: .optimal,
            optimalCount: 3, attentionCount: 0, criticalCount: 0, totalCount: 3
        )
        let status2 = CategorySystemStatus(
            id: id, category: .hormones, status: .optimal,
            optimalCount: 3, attentionCount: 0, criticalCount: 0, totalCount: 3
        )

        XCTAssertEqual(status1, status2)
    }

    // MARK: - Cache Invalidation Tests

    func testCacheInvalidation_BiomarkerSummariesDidSet() {
        // Set up initial data and access filtered to populate cache
        sut.biomarkerSummaries = makeSummaries()
        _ = sut.filteredBiomarkers

        // Change summaries which should invalidate cache
        let newSummary = makeSummary(name: "New Marker", category: .other, status: .normal)
        sut.biomarkerSummaries = [newSummary]

        let filtered = sut.filteredBiomarkers
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "New Marker")
    }

    func testCacheInvalidation_SelectedCategoryDidSet() {
        sut.biomarkerSummaries = makeSummaries()
        _ = sut.filteredBiomarkers

        // Change category which should invalidate cache
        sut.selectedCategory = .inflammation

        let filtered = sut.filteredBiomarkers
        XCTAssertTrue(filtered.allSatisfy { $0.category == .inflammation })
    }

    func testCacheInvalidation_SearchTextDidSet() {
        sut.biomarkerSummaries = makeSummaries()
        _ = sut.filteredBiomarkers

        // Change search text which should invalidate cache
        sut.searchText = "CRP"

        let filtered = sut.filteredBiomarkers
        XCTAssertTrue(filtered.allSatisfy {
            $0.name.lowercased().contains("crp") || $0.displayName.lowercased().contains("crp")
        })
    }

    // MARK: - Helper Methods

    /// Creates a minimal BiomarkerSummary with customizable fields
    private func makeSummary(
        name: String = "Test Marker",
        displayName: String? = nil,
        category: BiomarkerCategory = .other,
        currentValue: Double = 50.0,
        unit: String = "mg/dL",
        status: BiomarkerStatus = .normal,
        trend: BiomarkerTrend = .unknown,
        lastUpdated: Date = TestDates.reference,
        historyCount: Int = 1
    ) -> BiomarkerSummary {
        BiomarkerSummary(
            name: name,
            displayName: displayName,
            category: category,
            currentValue: currentValue,
            unit: unit,
            status: status,
            trend: trend,
            lastUpdated: lastUpdated,
            historyCount: historyCount
        )
    }

    /// Creates a representative set of biomarker summaries for testing
    private func makeSummaries() -> [BiomarkerSummary] {
        [
            makeSummary(name: "CRP", displayName: "C-Reactive Protein", category: .inflammation, currentValue: 1.2, status: .normal),
            makeSummary(name: "Testosterone", displayName: "Testosterone", category: .hormones, currentValue: 450.0, status: .optimal),
            makeSummary(name: "Glucose", displayName: "Glucose", category: .metabolic, currentValue: 95.0, status: .normal),
            makeSummary(name: "Vitamin D", displayName: "Vitamin D", category: .vitamins, currentValue: 35.0, status: .low),
            makeSummary(name: "Ferritin", displayName: "Ferritin", category: .minerals, currentValue: 85.0, status: .optimal),
            makeSummary(name: "LDL Cholesterol", displayName: "LDL Cholesterol", category: .lipidPanel, currentValue: 120.0, status: .high),
            makeSummary(name: "TSH", displayName: "TSH", category: .thyroid, currentValue: 2.5, status: .optimal),
            makeSummary(name: "Hemoglobin", displayName: "Hemoglobin", category: .cbc, currentValue: 14.5, status: .normal),
            makeSummary(name: "ALT", displayName: "ALT", category: .liver, currentValue: 28.0, status: .normal),
            makeSummary(name: "Creatinine", displayName: "Creatinine", category: .kidney, currentValue: 1.1, status: .normal)
        ]
    }
}
