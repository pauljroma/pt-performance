//
//  ComponentSnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for common reusable components.
//  Tests buttons, cards, charts, loading states, and design system elements
//  across different states, color schemes, and accessibility configurations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class ComponentSnapshotTests: SnapshotTestCase {

    // MARK: - Button Style Tests

    func testPrimaryButtonStyle_LightMode() {
        let view = Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 300)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "PrimaryButtonStyle_Light")
    }

    func testPrimaryButtonStyle_DarkMode() {
        let view = Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 300)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "PrimaryButtonStyle_Dark")
    }

    func testPrimaryButtonStyle_Disabled() {
        let view = Button("Disabled Button") {}
            .buttonStyle(PrimaryButtonStyle(isDisabled: true))
            .frame(width: 300)
            .padding()

        verifyViewRenders(view, named: "PrimaryButtonStyle_Disabled")
    }

    func testPrimaryButtonStyle_Loading() {
        let view = Button("Loading...") {}
            .buttonStyle(PrimaryButtonStyle(isLoading: true))
            .frame(width: 300)
            .padding()

        verifyViewRenders(view, named: "PrimaryButtonStyle_Loading")
    }

    func testSecondaryButtonStyle_LightMode() {
        let view = Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 300)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "SecondaryButtonStyle_Light")
    }

    func testSecondaryButtonStyle_DarkMode() {
        let view = Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 300)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "SecondaryButtonStyle_Dark")
    }

    func testSecondaryButtonStyle_Disabled() {
        let view = Button("Disabled Secondary") {}
            .buttonStyle(SecondaryButtonStyle(isDisabled: true))
            .frame(width: 300)
            .padding()

        verifyViewRenders(view, named: "SecondaryButtonStyle_Disabled")
    }

    func testDestructiveButtonStyle_LightMode() {
        let view = Button("Delete") {}
            .buttonStyle(DestructiveButtonStyle())
            .frame(width: 300)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "DestructiveButtonStyle_Light")
    }

    func testDestructiveButtonStyle_DarkMode() {
        let view = Button("Delete") {}
            .buttonStyle(DestructiveButtonStyle())
            .frame(width: 300)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "DestructiveButtonStyle_Dark")
    }

    func testButtonStyles_BothColorSchemes() {
        let view = VStack(spacing: 16) {
            Button("Primary") {}
                .buttonStyle(PrimaryButtonStyle())
            Button("Secondary") {}
                .buttonStyle(SecondaryButtonStyle())
            Button("Destructive") {}
                .buttonStyle(DestructiveButtonStyle())
        }
        .frame(width: 300)
        .padding()

        verifyViewInBothColorSchemes(view, named: "ButtonStyles")
    }

    // MARK: - LoadingButton Tests

    func testLoadingButton_Normal() {
        let view = LoadingButton(
            title: "Submit",
            icon: "checkmark",
            isLoading: false,
            action: {}
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "LoadingButton_Normal")
    }

    func testLoadingButton_Loading() {
        let view = LoadingButton(
            title: "Submit",
            icon: "checkmark",
            isLoading: true,
            action: {}
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "LoadingButton_Loading")
    }

    func testLoadingButton_Disabled() {
        let view = LoadingButton(
            title: "Submit",
            icon: "checkmark",
            isLoading: false,
            action: {},
            isDisabled: true
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "LoadingButton_Disabled")
    }

    func testLoadingButton_Styles() {
        let view = VStack(spacing: 16) {
            LoadingButton(
                title: "Primary",
                icon: "checkmark",
                isLoading: false,
                action: {},
                style: .primary
            )
            LoadingButton(
                title: "Secondary",
                icon: nil,
                isLoading: false,
                action: {},
                style: .secondary
            )
            LoadingButton(
                title: "Delete",
                icon: "trash",
                isLoading: false,
                action: {},
                style: .destructive
            )
        }
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "LoadingButton_AllStyles")
    }

    // MARK: - Card Component Tests

    func testCard_LightMode() {
        let view = Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("This is card content that demonstrates the card component.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "Card_Light")
    }

    func testCard_DarkMode() {
        let view = Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("This is card content that demonstrates the card component.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "Card_Dark")
    }

    func testCard_CustomCornerRadius() {
        let view = Card(cornerRadius: CornerRadius.xl) {
            Text("Large Corner Radius Card")
        }
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "Card_LargeRadius")
    }

    func testCard_CustomPadding() {
        let view = Card(padding: Spacing.xl) {
            Text("Extra Padding Card")
        }
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "Card_ExtraPadding")
    }

    func testTappableCard_LightMode() {
        let view = TappableCard(action: {}) {
            HStack {
                Text("Tappable Card")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "TappableCard_Light")
    }

    func testTappableCard_DarkMode() {
        let view = TappableCard(action: {}) {
            HStack {
                Text("Tappable Card")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "TappableCard_Dark")
    }

    // MARK: - Empty State View Tests

    func testEmptyStateView_WithAction_LightMode() {
        let view = EmptyStateView(
            title: "No Data Yet",
            message: "Get started by creating your first workout",
            icon: "dumbbell.fill",
            iconColor: .blue,
            action: EmptyStateView.EmptyStateAction(
                title: "Create Workout",
                icon: "plus.circle",
                action: {}
            )
        )
        .frame(width: 350, height: 400)
        .lightModeTest()

        verifyViewRenders(view, named: "EmptyStateView_WithAction_Light")
    }

    func testEmptyStateView_WithAction_DarkMode() {
        let view = EmptyStateView(
            title: "No Data Yet",
            message: "Get started by creating your first workout",
            icon: "dumbbell.fill",
            iconColor: .blue,
            action: EmptyStateView.EmptyStateAction(
                title: "Create Workout",
                icon: "plus.circle",
                action: {}
            )
        )
        .frame(width: 350, height: 400)
        .darkModeTest()

        verifyViewRenders(view, named: "EmptyStateView_WithAction_Dark")
    }

    func testEmptyStateView_WithoutAction() {
        let view = EmptyStateView(
            title: "No Results Found",
            message: "Try adjusting your search filters",
            icon: "magnifyingglass"
        )
        .frame(width: 350, height: 400)

        verifyViewRenders(view, named: "EmptyStateView_NoAction")
    }

    func testEmptyStateView_BothColorSchemes() {
        let view = EmptyStateView(
            title: "No Data Yet",
            message: "Get started by creating your first item",
            icon: "tray.fill"
        )
        .frame(width: 350, height: 400)

        verifyViewInBothColorSchemes(view, named: "EmptyStateView")
    }

    func testEmptyStateView_AccessibilityTextSizes() {
        let view = EmptyStateView(
            title: "No Data Yet",
            message: "Get started by creating your first item",
            icon: "tray.fill"
        )
        .frame(width: 350, height: 400)

        verifyViewAcrossDynamicTypeSizes(view, named: "EmptyStateView")
    }

    // MARK: - Loading State Tests

    func testSkeletonCard_LightMode() {
        let view = SkeletonCard()
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "SkeletonCard_Light")
    }

    func testSkeletonCard_DarkMode() {
        let view = SkeletonCard()
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "SkeletonCard_Dark")
    }

    func testSkeletonListRow_LightMode() {
        let view = SkeletonListRow()
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "SkeletonListRow_Light")
    }

    func testSkeletonListRow_DarkMode() {
        let view = SkeletonListRow()
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "SkeletonListRow_Dark")
    }

    func testLoadingStateView_LightMode() {
        let view = LoadingStateView()
            .lightModeTest()

        verifyViewRenders(view, named: "LoadingStateView_Light")
    }

    func testLoadingStateView_DarkMode() {
        let view = LoadingStateView()
            .darkModeTest()

        verifyViewRenders(view, named: "LoadingStateView_Dark")
    }

    func testChartLoadingView_LightMode() {
        let view = ChartLoadingView()
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "ChartLoadingView_Light")
    }

    func testChartLoadingView_DarkMode() {
        let view = ChartLoadingView()
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "ChartLoadingView_Dark")
    }

    func testTodaySessionLoadingView() {
        let view = TodaySessionLoadingView()

        verifyViewRenders(view, named: "TodaySessionLoadingView")
    }

    func testGoalsLoadingView() {
        let view = GoalsLoadingView()

        verifyViewRenders(view, named: "GoalsLoadingView")
    }

    func testNutritionDashboardLoadingView() {
        let view = NutritionDashboardLoadingView()

        verifyViewRenders(view, named: "NutritionDashboardLoadingView")
    }

    func testLoadingStates_BothColorSchemes() {
        let view = VStack(spacing: 16) {
            SkeletonCard()
            SkeletonListRow()
        }
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "LoadingStates")
    }

    // MARK: - Error State View Tests

    func testErrorStateView_LightMode() {
        let view = ErrorStateView(
            error: NSError(
                domain: "TestError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load data"]
            ),
            retryAction: {}
        )
        .frame(width: 350, height: 300)
        .lightModeTest()

        verifyViewRenders(view, named: "ErrorStateView_Light")
    }

    func testErrorStateView_DarkMode() {
        let view = ErrorStateView(
            error: NSError(
                domain: "TestError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load data"]
            ),
            retryAction: {}
        )
        .frame(width: 350, height: 300)
        .darkModeTest()

        verifyViewRenders(view, named: "ErrorStateView_Dark")
    }

    func testErrorStateView_BothColorSchemes() {
        let view = ErrorStateView(
            error: NSError(
                domain: "TestError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Something went wrong"]
            ),
            retryAction: {}
        )
        .frame(width: 350, height: 300)

        verifyViewInBothColorSchemes(view, named: "ErrorStateView")
    }

    // MARK: - Sync Status Indicator Tests

    func testSyncStatusIndicator_LightMode() {
        let view = SyncStatusIndicator()
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "SyncStatusIndicator_Light")
    }

    func testSyncStatusIndicator_DarkMode() {
        let view = SyncStatusIndicator()
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "SyncStatusIndicator_Dark")
    }

    // MARK: - Offline Banner Tests

    func testOfflineBanner_LightMode() {
        let view = OfflineBanner()
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "OfflineBanner_Light")
    }

    func testOfflineBanner_DarkMode() {
        let view = OfflineBanner()
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "OfflineBanner_Dark")
    }

    // MARK: - Design System Spacing Tests

    func testSpacingSystem() {
        let view = VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xxs) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("xxs (4pt)")
            }
            HStack(spacing: Spacing.xs) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("xs (8pt)")
            }
            HStack(spacing: Spacing.sm) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("sm (12pt)")
            }
            HStack(spacing: Spacing.md) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("md (16pt)")
            }
            HStack(spacing: Spacing.lg) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("lg (24pt)")
            }
            HStack(spacing: Spacing.xl) {
                Rectangle().fill(Color.blue).frame(width: 20, height: 20)
                Text("xl (32pt)")
            }
        }
        .padding()

        verifyViewRenders(view, named: "SpacingSystem")
    }

    // MARK: - Corner Radius Tests

    func testCornerRadiusSystem() {
        let view = VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                Text("xs (4pt)")
            }
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                Text("sm (8pt)")
            }
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                Text("md (12pt)")
            }
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                Text("lg (16pt)")
            }
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                Text("xl (24pt)")
            }
        }
        .padding()

        verifyViewRenders(view, named: "CornerRadiusSystem")
    }

    // MARK: - View Modifier Tests

    func testCardStyleModifier_LightMode() {
        let view = Text("Content with card style")
            .cardStyle()
            .frame(width: 300)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "CardStyleModifier_Light")
    }

    func testCardStyleModifier_DarkMode() {
        let view = Text("Content with card style")
            .cardStyle()
            .frame(width: 300)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "CardStyleModifier_Dark")
    }

    func testAdaptiveShadowModifier() {
        let view = VStack(spacing: Spacing.lg) {
            Text("Subtle shadow")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .adaptiveShadow(Shadow.subtle)

            Text("Medium shadow")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .adaptiveShadow(Shadow.medium)

            Text("Prominent shadow")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .adaptiveShadow(Shadow.prominent)
        }
        .padding()

        verifyViewInBothColorSchemes(view, named: "AdaptiveShadows")
    }

    // MARK: - Comprehensive Component Gallery

    func testComponentGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: Spacing.lg) {
                // Buttons section
                VStack(spacing: Spacing.sm) {
                    Text("Buttons").font(.headline)
                    Button("Primary") {}.buttonStyle(PrimaryButtonStyle())
                    Button("Secondary") {}.buttonStyle(SecondaryButtonStyle())
                    Button("Destructive") {}.buttonStyle(DestructiveButtonStyle())
                }
                .frame(width: 300)

                // Cards section
                VStack(spacing: Spacing.sm) {
                    Text("Cards").font(.headline)
                    Card { Text("Standard Card") }
                    TappableCard(action: {}) { Text("Tappable Card") }
                }
                .frame(width: 300)

                // Loading states section
                VStack(spacing: Spacing.sm) {
                    Text("Loading States").font(.headline)
                    SkeletonCard()
                }
                .frame(width: 300)
            }
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "ComponentGallery_Light")
    }

    func testComponentGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: Spacing.lg) {
                // Buttons section
                VStack(spacing: Spacing.sm) {
                    Text("Buttons").font(.headline)
                    Button("Primary") {}.buttonStyle(PrimaryButtonStyle())
                    Button("Secondary") {}.buttonStyle(SecondaryButtonStyle())
                    Button("Destructive") {}.buttonStyle(DestructiveButtonStyle())
                }
                .frame(width: 300)

                // Cards section
                VStack(spacing: Spacing.sm) {
                    Text("Cards").font(.headline)
                    Card { Text("Standard Card") }
                    TappableCard(action: {}) { Text("Tappable Card") }
                }
                .frame(width: 300)

                // Loading states section
                VStack(spacing: Spacing.sm) {
                    Text("Loading States").font(.headline)
                    SkeletonCard()
                }
                .frame(width: 300)
            }
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "ComponentGallery_Dark")
    }
}
