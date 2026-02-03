//
//  RecoverySnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for Recovery views.
//  Tests RecoveryInsightsView, BiomarkerTrendChartView, and
//  FastingWorkoutRecommendationView across different states and configurations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class RecoverySnapshotTests: SnapshotTestCase {

    // MARK: - RecoveryInsightsView Tests

    func testRecoveryInsightsView_WithData_LightMode() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.sample,
                onLogSession: { _ in }
            )
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "RecoveryInsightsView_WithData_Light")
    }

    func testRecoveryInsightsView_WithData_DarkMode() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.sample,
                onLogSession: { _ in }
            )
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "RecoveryInsightsView_WithData_Dark")
    }

    func testRecoveryInsightsView_EmptyState_LightMode() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.empty,
                onLogSession: { _ in }
            )
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "RecoveryInsightsView_Empty_Light")
    }

    func testRecoveryInsightsView_EmptyState_DarkMode() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.empty,
                onLogSession: { _ in }
            )
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "RecoveryInsightsView_Empty_Dark")
    }

    func testRecoveryInsightsView_BothColorSchemes() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.sample,
                onLogSession: { _ in }
            )
            .padding()
        }

        verifyViewInBothColorSchemes(view, named: "RecoveryInsightsView")
    }

    func testRecoveryInsightsView_AccessibilityTextSizes() {
        let view = ScrollView {
            RecoveryInsightsView(
                analysis: RecoveryImpactAnalysis.sample,
                onLogSession: { _ in }
            )
            .padding()
        }

        verifyViewAcrossDynamicTypeSizes(view, named: "RecoveryInsightsView")
    }

    // MARK: - RecoveryInsightCard Tests

    func testRecoveryInsightCard_PositiveImpact() {
        let insight = RecoveryInsight.sampleInsights.first(where: { $0.impactCategory == .positive || $0.impactCategory == .strongPositive })
            ?? RecoveryInsight.sampleInsights[0]

        let view = RecoveryInsightCard(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "RecoveryInsightCard_Positive")
    }

    func testRecoveryInsightCard_NeutralImpact() {
        let insight = RecoveryInsight.sampleInsights.first(where: { $0.impactCategory == .neutral })
            ?? RecoveryInsight.sampleInsights[0]

        let view = RecoveryInsightCard(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "RecoveryInsightCard_Neutral")
    }

    func testRecoveryInsightCard_NegativeImpact() {
        let insight = RecoveryInsight.sampleInsights.first(where: { $0.impactCategory == .negative || $0.impactCategory == .strongNegative })
            ?? RecoveryInsight.sampleInsights[0]

        let view = RecoveryInsightCard(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "RecoveryInsightCard_Negative")
    }

    func testRecoveryInsightCard_BothColorSchemes() {
        let insight = RecoveryInsight.sampleInsights[0]
        let view = RecoveryInsightCard(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "RecoveryInsightCard")
    }

    // MARK: - PersonalizedRecommendationCard Tests

    func testPersonalizedRecommendationCard_HighPriority() {
        let recommendation = PersonalizedRecoveryRecommendation.sampleRecommendations
            .first(where: { $0.priority == .high }) ?? PersonalizedRecoveryRecommendation.sampleRecommendations[0]

        let view = PersonalizedRecommendationCard(
            recommendation: recommendation,
            onLogSession: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "PersonalizedRecommendationCard_High")
    }

    func testPersonalizedRecommendationCard_MediumPriority() {
        let recommendation = PersonalizedRecoveryRecommendation.sampleRecommendations
            .first(where: { $0.priority == .medium }) ?? PersonalizedRecoveryRecommendation.sampleRecommendations[0]

        let view = PersonalizedRecommendationCard(
            recommendation: recommendation,
            onLogSession: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "PersonalizedRecommendationCard_Medium")
    }

    func testPersonalizedRecommendationCard_LowPriority() {
        let recommendation = PersonalizedRecoveryRecommendation.sampleRecommendations
            .first(where: { $0.priority == .low }) ?? PersonalizedRecoveryRecommendation.sampleRecommendations[0]

        let view = PersonalizedRecommendationCard(
            recommendation: recommendation,
            onLogSession: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "PersonalizedRecommendationCard_Low")
    }

    func testPersonalizedRecommendationCard_BothColorSchemes() {
        let recommendation = PersonalizedRecoveryRecommendation.sampleRecommendations[0]
        let view = PersonalizedRecommendationCard(
            recommendation: recommendation,
            onLogSession: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "PersonalizedRecommendationCard")
    }

    // MARK: - CompactInsightRow Tests

    func testCompactInsightRow_Positive() {
        let insight = RecoveryInsight.sampleInsights.first(where: { $0.impactPercentage >= 0 })
            ?? RecoveryInsight.sampleInsights[0]

        let view = CompactInsightRow(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "CompactInsightRow_Positive")
    }

    func testCompactInsightRow_Negative() {
        let insight = RecoveryInsight.sampleInsights.first(where: { $0.impactPercentage < 0 })
            ?? RecoveryInsight.sampleInsights[0]

        let view = CompactInsightRow(insight: insight)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "CompactInsightRow_Negative")
    }

    // MARK: - BiomarkerTrendChartView Tests

    func testBiomarkerTrendChartView_WithData_LightMode() {
        let sampleData = createSampleBiomarkerData()

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )
        .lightModeTest()

        verifyViewRenders(view, named: "BiomarkerTrendChartView_WithData_Light")
    }

    func testBiomarkerTrendChartView_WithData_DarkMode() {
        let sampleData = createSampleBiomarkerData()

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )
        .darkModeTest()

        verifyViewRenders(view, named: "BiomarkerTrendChartView_WithData_Dark")
    }

    func testBiomarkerTrendChartView_EmptyState_LightMode() {
        let view = BiomarkerTrendChartView(
            dataPoints: [],
            biomarkerName: "Testosterone"
        )
        .lightModeTest()

        verifyViewRenders(view, named: "BiomarkerTrendChartView_Empty_Light")
    }

    func testBiomarkerTrendChartView_EmptyState_DarkMode() {
        let view = BiomarkerTrendChartView(
            dataPoints: [],
            biomarkerName: "Testosterone"
        )
        .darkModeTest()

        verifyViewRenders(view, named: "BiomarkerTrendChartView_Empty_Dark")
    }

    func testBiomarkerTrendChartView_OptimalValues() {
        let sampleData = createSampleBiomarkerData(valueRange: 55...65) // Within optimal range

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )

        verifyViewRenders(view, named: "BiomarkerTrendChartView_Optimal")
    }

    func testBiomarkerTrendChartView_ConcerningValues() {
        let sampleData = createSampleBiomarkerData(valueRange: 20...35) // Below normal

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )

        verifyViewRenders(view, named: "BiomarkerTrendChartView_Concerning")
    }

    func testBiomarkerTrendChartView_BothColorSchemes() {
        let sampleData = createSampleBiomarkerData()

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )

        verifyViewInBothColorSchemes(view, named: "BiomarkerTrendChartView")
    }

    func testBiomarkerTrendChartView_AccessibilityTextSizes() {
        let sampleData = createSampleBiomarkerData()

        let view = BiomarkerTrendChartView(
            dataPoints: sampleData,
            biomarkerName: "Vitamin D"
        )

        verifyViewAcrossDynamicTypeSizes(view, named: "BiomarkerTrendChartView")
    }

    // MARK: - FastingWorkoutRecommendationView Tests

    func testFastingWorkoutRecommendationView_FullCapacity_LightMode() {
        let recommendation = createFastingRecommendation(intensityPercentage: 95)

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }
        .lightModeTest()

        verifyViewRenders(view, named: "FastingWorkoutRecommendation_Full_Light")
    }

    func testFastingWorkoutRecommendationView_FullCapacity_DarkMode() {
        let recommendation = createFastingRecommendation(intensityPercentage: 95)

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }
        .darkModeTest()

        verifyViewRenders(view, named: "FastingWorkoutRecommendation_Full_Dark")
    }

    func testFastingWorkoutRecommendationView_ReducedCapacity() {
        let recommendation = createFastingRecommendation(
            intensityPercentage: 70,
            safetyWarnings: ["Glycogen stores are depleted", "Break fast within 2 hours post-workout"]
        )

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }

        verifyViewRenders(view, named: "FastingWorkoutRecommendation_Reduced")
    }

    func testFastingWorkoutRecommendationView_RestRecommended() {
        let recommendation = createFastingRecommendation(
            intensityPercentage: 40,
            workoutRecommended: false,
            safetyWarnings: ["Extended fasting - rest recommended", "Risk of hypoglycemia during intense exercise"]
        )

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }

        verifyViewRenders(view, named: "FastingWorkoutRecommendation_Rest")
    }

    func testFastingWorkoutRecommendationView_BothColorSchemes() {
        let recommendation = createFastingRecommendation(intensityPercentage: 80)

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }

        verifyViewInBothColorSchemes(view, named: "FastingWorkoutRecommendationView")
    }

    func testFastingWorkoutRecommendationView_AccessibilityTextSizes() {
        let recommendation = createFastingRecommendation(intensityPercentage: 80)

        let view = ScrollView {
            FastingWorkoutRecommendationView(recommendation: recommendation)
        }

        verifyViewAcrossDynamicTypeSizes(view, named: "FastingWorkoutRecommendationView")
    }

    // MARK: - FastingWorkoutRecommendationCompactView Tests

    func testFastingWorkoutRecommendationCompactView_FullCapacity() {
        let recommendation = createFastingRecommendation(intensityPercentage: 95)

        let view = FastingWorkoutRecommendationCompactView(
            recommendation: recommendation,
            onTapExpand: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "FastingRecommendationCompact_Full")
    }

    func testFastingWorkoutRecommendationCompactView_WithWarnings() {
        let recommendation = createFastingRecommendation(
            intensityPercentage: 65,
            safetyWarnings: ["Stay hydrated", "Reduce intensity"]
        )

        let view = FastingWorkoutRecommendationCompactView(
            recommendation: recommendation,
            onTapExpand: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "FastingRecommendationCompact_Warnings")
    }

    func testFastingWorkoutRecommendationCompactView_BothColorSchemes() {
        let recommendation = createFastingRecommendation(intensityPercentage: 80)

        let view = FastingWorkoutRecommendationCompactView(
            recommendation: recommendation,
            onTapExpand: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "FastingRecommendationCompact")
    }

    // MARK: - WarningCard Tests

    func testWarningCard_HighSeverity() {
        let view = WarningCard(
            message: "Not recommended during extended fasting - risk of hypoglycemia",
            severity: .high
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "WarningCard_High")
    }

    func testWarningCard_MediumSeverity() {
        let view = WarningCard(
            message: "Reduce training volume by 20-30%",
            severity: .medium
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "WarningCard_Medium")
    }

    func testWarningCard_LowSeverity() {
        let view = WarningCard(
            message: "Consider breaking fast 1 hour before training",
            severity: .low
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "WarningCard_Low")
    }

    func testWarningCard_BothColorSchemes() {
        let view = WarningCard(
            message: "Sample warning message",
            severity: .medium
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "WarningCard")
    }

    // MARK: - NutritionTimingRow Tests

    func testNutritionTimingRow_PreWorkout() {
        let view = NutritionTimingRow(
            label: "Pre-Workout",
            value: "BCAAs or EAAs (5-10g)",
            icon: "arrow.right.circle.fill",
            color: .blue
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "NutritionTimingRow_Pre")
    }

    func testNutritionTimingRow_PostWorkout() {
        let view = NutritionTimingRow(
            label: "Post-Workout",
            value: "Break fast immediately with protein shake (40g)",
            icon: "checkmark.circle.fill",
            color: .green
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "NutritionTimingRow_Post")
    }

    // MARK: - Helper Methods

    private func createSampleBiomarkerData(valueRange: ClosedRange<Double> = 45...85) -> [BiomarkerTrendPoint] {
        return (0..<8).map { week in
            BiomarkerTrendPoint(
                date: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
                value: Double.random(in: valueRange),
                biomarkerType: "vitamin_d",
                unit: "ng/mL",
                optimalLow: 50,
                optimalHigh: 70,
                normalLow: 30,
                normalHigh: 100
            )
        }.reversed()
    }

    private func createFastingRecommendation(
        intensityPercentage: Int = 80,
        workoutRecommended: Bool = true,
        safetyWarnings: [String] = []
    ) -> FastingWorkoutRecommendation {
        return FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: FastingStateResponse(
                isFasting: true,
                startedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(intensityPercentage >= 90 ? 14 : 18) * 3600)),
                fastingHours: intensityPercentage >= 90 ? 14 : 18,
                protocolType: "16_8",
                plannedHours: 16
            ),
            workoutAllowed: true,
            workoutRecommended: workoutRecommended,
            modifications: [],
            nutritionTiming: NutritionTiming(
                recommendation: "Plan your nutrition timing carefully.",
                preWorkout: intensityPercentage < 80 ? "Consider BCAAs or EAAs (5-10g)" : nil,
                intraWorkout: intensityPercentage < 70 ? "Electrolytes with sodium" : nil,
                postWorkout: "Protein shake within 30 minutes",
                timingNotes: ""
            ),
            safetyWarnings: safetyWarnings,
            performanceNotes: [],
            electrolyteRecommendations: ["Stay hydrated", "Electrolytes recommended"],
            alternativeWorkoutSuggestion: intensityPercentage < 60 ? "Light walking or yoga" : nil,
            disclaimer: "Individual responses vary."
        )
    }
}
