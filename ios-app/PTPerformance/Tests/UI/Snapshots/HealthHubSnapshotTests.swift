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

// MARK: - FastingTrackerView Component Tests

    func testFastingStatusCard_Active_LightMode() {
        // Test the fasting status indicator component
        let view = VStack(spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 3)
                    )

                Text("Fasting")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                Text("Started 2:30 PM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("14h 30m")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1h 30m")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "FastingStatusCard_Active_Light")
    }

    func testFastingStatusCard_Active_DarkMode() {
        let view = VStack(spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 12, height: 12)

                Text("Fasting")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("18h 00m")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Goal Reached!")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("0h 00m")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "FastingStatusCard_Active_Dark")
    }

    func testFastingStatusCard_EatingWindow() {
        let view = VStack(spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 12, height: 12)

                Text("Eating Window")
                    .font(.headline)
                    .foregroundColor(.orange)

                Spacer()
            }

            Text("Tap below to start your fasting window")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "FastingStatusCard_EatingWindow")
    }

    func testFastingStreakCard_LightMode() {
        let view = HStack(spacing: Spacing.lg) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("7")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("14")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "FastingStreakCard_Light")
    }

    func testFastingStreakCard_DarkMode() {
        let view = HStack(spacing: Spacing.lg) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("21")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("21")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "FastingStreakCard_Dark")
    }

    // MARK: - Recovery Tracking Component Tests

    func testRecoveryStreakCard_LightMode() {
        let view = VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("5 Day Streak")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Keep going! You're building great habits.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best: 14")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("Today", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "RecoveryStreakCard_Light")
    }

    func testRecoveryStreakCard_DarkMode() {
        let view = VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("30 Day Streak")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Incredible consistency! Champion level!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best: 30")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "RecoveryStreakCard_Dark")
    }

    // MARK: - Biomarker Dashboard Component Tests

    func testBiomarkerStatusOverview_LightMode() {
        let view = VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)

                Spacer()

                Text("Updated Jan 15, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                StatusCountCardView(count: 8, label: "Optimal", color: .green, icon: "checkmark.circle.fill")
                StatusCountCardView(count: 4, label: "Normal", color: .blue, icon: "circle.fill")
                StatusCountCardView(count: 2, label: "Attention", color: .orange, icon: "exclamationmark.circle.fill")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "BiomarkerStatusOverview_Light")
    }

    func testBiomarkerStatusOverview_DarkMode() {
        let view = VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)

                Spacer()

                Text("Updated Feb 1, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                StatusCountCardView(count: 12, label: "Optimal", color: .green, icon: "checkmark.circle.fill")
                StatusCountCardView(count: 5, label: "Normal", color: .blue, icon: "circle.fill")
                StatusCountCardView(count: 0, label: "Attention", color: .orange, icon: "exclamationmark.circle.fill")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "BiomarkerStatusOverview_Dark")
    }

    func testBiomarkerAttentionSection_LightMode() {
        let view = VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Needs Attention")
                    .font(.headline)

                Spacer()

                Text("2 markers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Sample biomarker rows
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Vitamin D")
                        .font(.subheadline)
                    Spacer()
                    Text("18 ng/mL")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("Low")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("Iron")
                        .font(.subheadline)
                    Spacer()
                    Text("45 mcg/dL")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("Low")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "BiomarkerAttentionSection_Light")
    }

    func testBiomarkerAttentionSection_DarkMode() {
        let view = VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Needs Attention")
                    .font(.headline)

                Spacer()

                Text("3 markers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Testosterone")
                        .font(.subheadline)
                    Spacer()
                    Text("Low")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.orange)
                }
            }

            Text("+ 2 more")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "BiomarkerAttentionSection_Dark")
    }

    // MARK: - Supplement List Component Tests

    func testSupplementCard_LightMode() {
        let view = VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Vitamin D3")
                        .font(.headline)
                    Text("5000 IU daily")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Text("Taken with breakfast")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "SupplementCard_Light")
    }

    func testSupplementCard_DarkMode() {
        let view = VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fish Oil")
                        .font(.headline)
                    Text("2000mg EPA/DHA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }

            Text("Take with food")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "SupplementCard_Dark")
    }

    func testSupplementList_BothColorSchemes() {
        let view = VStack(spacing: 12) {
            ForEach(["Vitamin D3", "Fish Oil", "Magnesium"], id: \.self) { name in
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)

                    Text(name)
                        .font(.subheadline)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "SupplementList")
    }

    // MARK: - HealthHub Gallery Tests

    func testHealthHubComponentsGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                HealthScoreCard()

                HStack(spacing: 12) {
                    StatusCountCardView(count: 8, label: "Optimal", color: .green, icon: "checkmark.circle.fill")
                    StatusCountCardView(count: 4, label: "Normal", color: .blue, icon: "circle.fill")
                    StatusCountCardView(count: 1, label: "Attention", color: .orange, icon: "exclamationmark.circle.fill")
                }

                HealthFeatureCard(
                    title: "Lab Results",
                    icon: "cross.case.fill",
                    color: .red,
                    destination: AnyView(Text("Lab Results"))
                )
            }
            .frame(width: 350)
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "HealthHubComponentsGallery_Light")
    }

    func testHealthHubComponentsGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                HealthScoreCard()

                HStack(spacing: 12) {
                    StatusCountCardView(count: 10, label: "Optimal", color: .green, icon: "checkmark.circle.fill")
                    StatusCountCardView(count: 3, label: "Normal", color: .blue, icon: "circle.fill")
                    StatusCountCardView(count: 0, label: "Attention", color: .orange, icon: "exclamationmark.circle.fill")
                }

                HealthFeatureCard(
                    title: "Recovery",
                    icon: "heart.fill",
                    color: .pink,
                    destination: AnyView(Text("Recovery"))
                )
            }
            .frame(width: 350)
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "HealthHubComponentsGallery_Dark")
    }

    func testHealthHubComponents_iPhoneAndIPad() {
        let view = VStack(spacing: 16) {
            HealthScoreCard()
            HealthFeatureCard(
                title: "Lab Results",
                icon: "cross.case.fill",
                color: .red,
                destination: AnyView(Text("Lab Results"))
            )
        }
        .padding()

        verifyViewAcrossDevices(
            view,
            named: "HealthHubComponents",
            devices: [.iPhone15Pro, .iPadPro]
        )
    }
}

// MARK: - Helper View for Status Count Card

private struct StatusCountCardView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
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
