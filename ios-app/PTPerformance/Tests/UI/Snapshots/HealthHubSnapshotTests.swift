//
//  HealthHubSnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for Health Hub views.
//  Tests HealthHubView, HealthScoreCard, UnifiedAICoachView across
//  different states, color schemes, and accessibility configurations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class HealthHubSnapshotTests: SnapshotTestCase {

    // MARK: - HealthHubView Tests

    func testHealthHubView_PremiumState_LightMode() {
        // Create a mock premium StoreKit service
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: true))
            .lightModeTest()

        verifyViewRenders(view, named: "HealthHubView_Premium_Light")
    }

    func testHealthHubView_PremiumState_DarkMode() {
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: true))
            .darkModeTest()

        verifyViewRenders(view, named: "HealthHubView_Premium_Dark")
    }

    func testHealthHubView_PaywallState_LightMode() {
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: false))
            .lightModeTest()

        verifyViewRenders(view, named: "HealthHubView_Paywall_Light")
    }

    func testHealthHubView_PaywallState_DarkMode() {
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: false))
            .darkModeTest()

        verifyViewRenders(view, named: "HealthHubView_Paywall_Dark")
    }

    func testHealthHubView_AccessibilityTextSizes() {
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: true))

        verifyViewAcrossDynamicTypeSizes(view, named: "HealthHubView_Premium")
    }

    func testHealthHubView_BothColorSchemes() {
        let view = HealthHubView()
            .environmentObject(MockStoreKitService(isPremium: true))

        verifyViewInBothColorSchemes(view, named: "HealthHubView_Premium")
    }

    // MARK: - HealthScoreCard Tests

    func testHealthScoreCard_LightMode() {
        let view = HealthScoreCard()
            .lightModeTest()
            .frame(width: 350)

        verifyViewRenders(view, named: "HealthScoreCard_Light")
    }

    func testHealthScoreCard_DarkMode() {
        let view = HealthScoreCard()
            .darkModeTest()
            .frame(width: 350)

        verifyViewRenders(view, named: "HealthScoreCard_Dark")
    }

    func testHealthScoreCard_BothColorSchemes() {
        let view = HealthScoreCard()
            .frame(width: 350)

        verifyViewInBothColorSchemes(view, named: "HealthScoreCard")
    }

    func testHealthScoreCard_AccessibilityTextSizes() {
        let view = HealthScoreCard()
            .frame(width: 350)

        verifyViewAcrossDynamicTypeSizes(view, named: "HealthScoreCard")
    }

    // MARK: - HealthScoreRow Tests

    func testHealthScoreRow_HighScore() {
        let view = HealthScoreRow(label: "Sleep", value: 85)
            .frame(width: 200)

        verifyViewRenders(view, named: "HealthScoreRow_High")
    }

    func testHealthScoreRow_MediumScore() {
        let view = HealthScoreRow(label: "Recovery", value: 65)
            .frame(width: 200)

        verifyViewRenders(view, named: "HealthScoreRow_Medium")
    }

    func testHealthScoreRow_LowScore() {
        let view = HealthScoreRow(label: "Activity", value: 35)
            .frame(width: 200)

        verifyViewRenders(view, named: "HealthScoreRow_Low")
    }

    func testHealthScoreRow_BothColorSchemes() {
        let view = HealthScoreRow(label: "Sleep", value: 75)
            .frame(width: 200)

        verifyViewInBothColorSchemes(view, named: "HealthScoreRow")
    }

    // MARK: - HealthFeatureCard Tests

    func testHealthFeatureCard_LabResults() {
        let view = HealthFeatureCard(
            title: "Lab Results",
            icon: "cross.case.fill",
            color: .red,
            destination: AnyView(Text("Lab Results"))
        )
        .frame(width: 170)

        verifyViewRenders(view, named: "HealthFeatureCard_LabResults")
    }

    func testHealthFeatureCard_Recovery() {
        let view = HealthFeatureCard(
            title: "Recovery",
            icon: "heart.fill",
            color: .pink,
            destination: AnyView(Text("Recovery"))
        )
        .frame(width: 170)

        verifyViewRenders(view, named: "HealthFeatureCard_Recovery")
    }

    func testHealthFeatureCard_Fasting() {
        let view = HealthFeatureCard(
            title: "Fasting",
            icon: "fork.knife.circle.fill",
            color: .green,
            destination: AnyView(Text("Fasting"))
        )
        .frame(width: 170)

        verifyViewRenders(view, named: "HealthFeatureCard_Fasting")
    }

    func testHealthFeatureCard_BothColorSchemes() {
        let view = HealthFeatureCard(
            title: "Supplements",
            icon: "pill.fill",
            color: .orange,
            destination: AnyView(Text("Supplements"))
        )
        .frame(width: 170)

        verifyViewInBothColorSchemes(view, named: "HealthFeatureCard")
    }

    // MARK: - HealthFeatureRow Tests (Paywall)

    func testHealthFeatureRow_LightMode() {
        let view = HealthFeatureRow(icon: "cross.case.fill", text: "Lab Results Analysis")
            .frame(width: 300)
            .lightModeTest()

        verifyViewRenders(view, named: "HealthFeatureRow_Light")
    }

    func testHealthFeatureRow_DarkMode() {
        let view = HealthFeatureRow(icon: "heart.fill", text: "Recovery Protocol Tracking")
            .frame(width: 300)
            .darkModeTest()

        verifyViewRenders(view, named: "HealthFeatureRow_Dark")
    }

    // MARK: - QuickActionPreview Tests

    func testQuickActionPreview_Variations() {
        let view = HStack(spacing: 12) {
            QuickActionPreview(icon: "moon.fill", label: "Sleep")
            QuickActionPreview(icon: "heart.fill", label: "Recovery")
            QuickActionPreview(icon: "figure.run", label: "Training")
            QuickActionPreview(icon: "cross.case.fill", label: "Labs")
        }
        .padding()

        verifyViewRenders(view, named: "QuickActionPreview_Variations")
    }

    func testQuickActionPreview_BothColorSchemes() {
        let view = QuickActionPreview(icon: "moon.fill", label: "Sleep")
            .padding()

        verifyViewInBothColorSchemes(view, named: "QuickActionPreview")
    }

    // MARK: - UnifiedAICoachView Tests

    func testUnifiedAICoachView_LightMode() {
        let view = UnifiedAICoachView()
            .lightModeTest()

        verifyViewRenders(view, named: "UnifiedAICoachView_Light")
    }

    func testUnifiedAICoachView_DarkMode() {
        let view = UnifiedAICoachView()
            .darkModeTest()

        verifyViewRenders(view, named: "UnifiedAICoachView_Dark")
    }

    func testUnifiedAICoachView_BothColorSchemes() {
        let view = UnifiedAICoachView()

        verifyViewInBothColorSchemes(view, named: "UnifiedAICoachView")
    }

    func testUnifiedAICoachView_AccessibilityTextSizes() {
        let view = UnifiedAICoachView()

        verifyViewAcrossDynamicTypeSizes(view, named: "UnifiedAICoachView")
    }

    // MARK: - CoachTypingIndicator Tests

    func testCoachTypingIndicator_LightMode() {
        let view = CoachTypingIndicator()
            .lightModeTest()
            .frame(width: 200)

        verifyViewRenders(view, named: "CoachTypingIndicator_Light")
    }

    func testCoachTypingIndicator_DarkMode() {
        let view = CoachTypingIndicator()
            .darkModeTest()
            .frame(width: 200)

        verifyViewRenders(view, named: "CoachTypingIndicator_Dark")
    }

    // MARK: - SuggestedQuestionChip Tests

    func testSuggestedQuestionChip_Variations() {
        let view = VStack(spacing: 8) {
            SuggestedQuestionChip(question: "How's my sleep quality?", action: {})
            SuggestedQuestionChip(question: "What should I eat today?", action: {})
            SuggestedQuestionChip(question: "Am I recovered enough to train?", action: {})
        }
        .padding()

        verifyViewRenders(view, named: "SuggestedQuestionChip_Variations")
    }

    func testSuggestedQuestionChip_BothColorSchemes() {
        let view = SuggestedQuestionChip(question: "How's my recovery?", action: {})
            .padding()

        verifyViewInBothColorSchemes(view, named: "SuggestedQuestionChip")
    }
}

// MARK: - Mock Services for Testing

/// Mock StoreKit service for testing premium/non-premium states
class MockStoreKitService: StoreKitService {
    private let mockIsPremium: Bool

    init(isPremium: Bool) {
        self.mockIsPremium = isPremium
        super.init()
    }

    override var isPremium: Bool {
        return mockIsPremium
    }
}
