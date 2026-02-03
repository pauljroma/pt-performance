//
//  PreviewVerificationTests.swift
//  PTPerformanceTests
//
//  Preview verification tests that ensure SwiftUI Previews compile and render.
//  These tests verify that preview definitions don't crash at runtime,
//  providing a safety net for catching preview-breaking changes.
//

import XCTest
import SwiftUI
@testable import PTPerformance

/// Tests that verify PreviewProvider implementations compile and render
final class PreviewVerificationTests: SnapshotTestCase {

    // MARK: - Health Hub Previews

    func testHealthHubView_PreviewsCompile() {
        // HealthHubView doesn't have explicit previews, verify direct instantiation
        let view = HealthHubView()
            .environmentObject(StoreKitService.shared)

        verifyViewRenders(view, named: "HealthHubView_Preview")
    }

    func testUnifiedAICoachView_PreviewsCompile() {
        // Verify the #Preview macro renders
        let view = UnifiedAICoachView()
        verifyViewRenders(view, named: "UnifiedAICoachView_Preview")
    }

    // MARK: - Recovery Previews

    func testRecoveryInsightsView_PreviewsCompile() {
        verifyPreviewsCompile(
            { RecoveryInsightsView_Previews.previews },
            named: "RecoveryInsightsView_Previews"
        )
    }

    func testRecoveryInsightCard_PreviewsCompile() {
        verifyPreviewsCompile(
            { RecoveryInsightCard_Previews.previews },
            named: "RecoveryInsightCard_Previews"
        )
    }

    func testPersonalizedRecommendationCard_PreviewsCompile() {
        verifyPreviewsCompile(
            { PersonalizedRecommendationCard_Previews.previews },
            named: "PersonalizedRecommendationCard_Previews"
        )
    }

    func testBiomarkerTrendChartView_PreviewsCompile() {
        verifyPreviewsCompile(
            { BiomarkerTrendChartView_Previews.previews },
            named: "BiomarkerTrendChartView_Previews"
        )
    }

    // MARK: - Workout Previews

    func testOptimisticWorkoutExecutionView_PreviewsCompile() {
        verifyPreviewsCompile(
            { OptimisticWorkoutExecutionView_Previews.previews },
            named: "OptimisticWorkoutExecutionView_Previews"
        )
    }

    func testOptimisticSetRow_PreviewsCompile() {
        verifyPreviewsCompile(
            { OptimisticSetRow_Previews.previews },
            named: "OptimisticSetRow_Previews"
        )
    }

    func testRestTimerOverlay_PreviewsCompile() {
        verifyPreviewsCompile(
            { RestTimerOverlay_Previews.previews },
            named: "RestTimerOverlay_Previews"
        )
    }

    // MARK: - Component Previews

    func testDesignSystem_PreviewsCompile() {
        verifyPreviewsCompile(
            { DesignSystem_Previews.previews },
            named: "DesignSystem_Previews"
        )
    }

    func testLoadingStateView_PreviewsCompile() {
        verifyPreviewsCompile(
            { LoadingStateView_Previews.previews },
            named: "LoadingStateView_Previews"
        )
    }

    // MARK: - Direct View Instantiation Tests

    /// These tests verify views can be instantiated with mock/sample data
    /// without crashing, even if they don't have PreviewProvider implementations

    func testHealthScoreCard_DirectInstantiation() {
        let view = HealthScoreCard()
        verifyViewRenders(view, named: "HealthScoreCard_Direct")
    }

    func testHealthScoreRow_DirectInstantiation() {
        let view = HealthScoreRow(label: "Sleep", value: 75)
        verifyViewRenders(view, named: "HealthScoreRow_Direct")
    }

    func testHealthFeatureCard_DirectInstantiation() {
        let view = HealthFeatureCard(
            title: "Recovery",
            icon: "heart.fill",
            color: .pink,
            destination: AnyView(Text("Destination"))
        )
        verifyViewRenders(view, named: "HealthFeatureCard_Direct")
    }

    func testHealthFeatureRow_DirectInstantiation() {
        let view = HealthFeatureRow(icon: "pill.fill", text: "Supplement Tracking")
        verifyViewRenders(view, named: "HealthFeatureRow_Direct")
    }

    func testQuickActionPreview_DirectInstantiation() {
        let view = QuickActionPreview(icon: "heart.fill", label: "Recovery")
        verifyViewRenders(view, named: "QuickActionPreview_Direct")
    }

    func testCoachTypingIndicator_DirectInstantiation() {
        let view = CoachTypingIndicator()
        verifyViewRenders(view, named: "CoachTypingIndicator_Direct")
    }

    func testSuggestedQuestionChip_DirectInstantiation() {
        let view = SuggestedQuestionChip(question: "How am I doing?", action: {})
        verifyViewRenders(view, named: "SuggestedQuestionChip_Direct")
    }

    // MARK: - Loading State Direct Instantiation

    func testSkeletonCard_DirectInstantiation() {
        let view = SkeletonCard()
        verifyViewRenders(view, named: "SkeletonCard_Direct")
    }

    func testSkeletonListRow_DirectInstantiation() {
        let view = SkeletonListRow()
        verifyViewRenders(view, named: "SkeletonListRow_Direct")
    }

    func testChartLoadingView_DirectInstantiation() {
        let view = ChartLoadingView()
        verifyViewRenders(view, named: "ChartLoadingView_Direct")
    }

    func testSessionListLoadingView_DirectInstantiation() {
        let view = SessionListLoadingView()
        verifyViewRenders(view, named: "SessionListLoadingView_Direct")
    }

    func testPatientListLoadingView_DirectInstantiation() {
        let view = PatientListLoadingView()
        verifyViewRenders(view, named: "PatientListLoadingView_Direct")
    }

    func testTodaySessionLoadingView_DirectInstantiation() {
        let view = TodaySessionLoadingView()
        verifyViewRenders(view, named: "TodaySessionLoadingView_Direct")
    }

    func testGoalsLoadingView_DirectInstantiation() {
        let view = GoalsLoadingView()
        verifyViewRenders(view, named: "GoalsLoadingView_Direct")
    }

    func testNutritionDashboardLoadingView_DirectInstantiation() {
        let view = NutritionDashboardLoadingView()
        verifyViewRenders(view, named: "NutritionDashboardLoadingView_Direct")
    }

    // MARK: - Button Style Direct Instantiation

    func testPrimaryButtonStyle_DirectInstantiation() {
        let view = Button("Test") {}
            .buttonStyle(PrimaryButtonStyle())
        verifyViewRenders(view, named: "PrimaryButtonStyle_Direct")
    }

    func testSecondaryButtonStyle_DirectInstantiation() {
        let view = Button("Test") {}
            .buttonStyle(SecondaryButtonStyle())
        verifyViewRenders(view, named: "SecondaryButtonStyle_Direct")
    }

    func testDestructiveButtonStyle_DirectInstantiation() {
        let view = Button("Test") {}
            .buttonStyle(DestructiveButtonStyle())
        verifyViewRenders(view, named: "DestructiveButtonStyle_Direct")
    }

    // MARK: - Card Direct Instantiation

    func testCard_DirectInstantiation() {
        let view = Card {
            Text("Test Content")
        }
        verifyViewRenders(view, named: "Card_Direct")
    }

    func testTappableCard_DirectInstantiation() {
        let view = TappableCard(action: {}) {
            Text("Test Content")
        }
        verifyViewRenders(view, named: "TappableCard_Direct")
    }

    // MARK: - Empty State Direct Instantiation

    func testEmptyStateView_DirectInstantiation() {
        let view = EmptyStateView(
            title: "Test Title",
            message: "Test message",
            icon: "tray.fill"
        )
        verifyViewRenders(view, named: "EmptyStateView_Direct")
    }

    func testEmptyStateView_WithAction_DirectInstantiation() {
        let view = EmptyStateView(
            title: "Test Title",
            message: "Test message",
            icon: "tray.fill",
            action: EmptyStateView.EmptyStateAction(
                title: "Action",
                icon: "plus",
                action: {}
            )
        )
        verifyViewRenders(view, named: "EmptyStateView_WithAction_Direct")
    }

    // MARK: - Loading Button Direct Instantiation

    func testLoadingButton_DirectInstantiation() {
        let view = LoadingButton(
            title: "Submit",
            icon: "checkmark",
            isLoading: false,
            action: {}
        )
        verifyViewRenders(view, named: "LoadingButton_Direct")
    }

    func testLoadingButton_Loading_DirectInstantiation() {
        let view = LoadingButton(
            title: "Submit",
            icon: "checkmark",
            isLoading: true,
            action: {}
        )
        verifyViewRenders(view, named: "LoadingButton_Loading_Direct")
    }

    // MARK: - Workout Components Direct Instantiation

    func testRestTimerOverlay_DirectInstantiation() {
        let view = RestTimerOverlay(
            timeRemaining: 60,
            totalTime: 90,
            onSkip: {}
        )
        verifyViewRenders(view, named: "RestTimerOverlay_Direct")
    }

    func testTappableRepCounter_DirectInstantiation() {
        let view = StatefulTestWrapper(10) { reps in
            TappableRepCounter(reps: reps, prescribedReps: 10)
        }
        verifyViewRenders(view, named: "TappableRepCounter_Direct")
    }

    func testSwipeableWeightControl_DirectInstantiation() {
        let view = StatefulTestWrapper(135.0) { weight in
            SwipeableWeightControl(weight: weight)
        }
        verifyViewRenders(view, named: "SwipeableWeightControl_Direct")
    }

    func testRepsEditorSheet_DirectInstantiation() {
        let view = StatefulTestWrapper(10) { reps in
            RepsEditorSheet(
                reps: reps,
                targetReps: 10,
                onDismiss: {}
            )
        }
        verifyViewRenders(view, named: "RepsEditorSheet_Direct")
    }

    func testWeightEditorSheet_DirectInstantiation() {
        let view = StatefulTestWrapper(135.0) { weight in
            WeightEditorSheet(
                weight: weight,
                loadUnit: "lbs",
                targetWeight: 135,
                onDismiss: {}
            )
        }
        verifyViewRenders(view, named: "WeightEditorSheet_Direct")
    }

    // MARK: - Recovery Components Direct Instantiation

    func testWarningCard_DirectInstantiation() {
        let view = WarningCard(
            message: "Test warning message",
            severity: .medium
        )
        verifyViewRenders(view, named: "WarningCard_Direct")
    }

    func testNutritionTimingRow_DirectInstantiation() {
        let view = NutritionTimingRow(
            label: "Pre-Workout",
            value: "BCAAs 5g",
            icon: "arrow.right.circle.fill",
            color: .blue
        )
        verifyViewRenders(view, named: "NutritionTimingRow_Direct")
    }

    // MARK: - Comprehensive View State Tests

    func testAllViewStates_LightMode() {
        // Test a representative view in light mode comprehensively
        let view = VStack(spacing: 20) {
            // Normal state
            Card { Text("Normal State") }

            // Empty state
            EmptyStateView(
                title: "Empty",
                message: "No data available",
                icon: "tray"
            )
            .frame(height: 200)

            // Loading state
            SkeletonCard()
        }
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "AllViewStates_Light")
    }

    func testAllViewStates_DarkMode() {
        let view = VStack(spacing: 20) {
            // Normal state
            Card { Text("Normal State") }

            // Empty state
            EmptyStateView(
                title: "Empty",
                message: "No data available",
                icon: "tray"
            )
            .frame(height: 200)

            // Loading state
            SkeletonCard()
        }
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "AllViewStates_Dark")
    }
}
