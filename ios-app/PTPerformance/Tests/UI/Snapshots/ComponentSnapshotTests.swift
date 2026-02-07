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

    // MARK: - TrafficLightIndicator Tests

    func testTrafficLightIndicator_Red() {
        let view = HStack(spacing: 16) {
            // Red indicator using RTSTrafficLight model colors
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.red)
                    .frame(width: 34, height: 34)

                Image(systemName: "xmark.octagon.fill")
                    .font(.body)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading) {
                Text("Restricted")
                    .font(.headline)
                Text("Focus on rehabilitation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()

        verifyViewRenders(view, named: "TrafficLightIndicator_Red")
    }

    func testTrafficLightIndicator_Yellow() {
        let view = HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.yellow)
                    .frame(width: 34, height: 34)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading) {
                Text("Caution")
                    .font(.headline)
                Text("Modified activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()

        verifyViewRenders(view, named: "TrafficLightIndicator_Yellow")
    }

    func testTrafficLightIndicator_Green() {
        let view = HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.green)
                    .frame(width: 34, height: 34)

                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading) {
                Text("Cleared")
                    .font(.headline)
                Text("Full activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()

        verifyViewRenders(view, named: "TrafficLightIndicator_Green")
    }

    func testTrafficLightIndicator_AllStates() {
        let view = HStack(spacing: 24) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 34, height: 34)
                    Image(systemName: "xmark.octagon.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Text("Red")
                    .font(.caption)
            }

            VStack {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 34, height: 34)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Text("Yellow")
                    .font(.caption)
            }

            VStack {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 34, height: 34)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Text("Green")
                    .font(.caption)
            }
        }
        .padding()

        verifyViewRenders(view, named: "TrafficLightIndicator_AllStates")
    }

    func testTrafficLightIndicator_BothColorSchemes() {
        let view = HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 48, height: 48)
                Circle()
                    .fill(Color.green)
                    .frame(width: 34, height: 34)
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.white)
            }
            Text("Cleared")
                .font(.headline)
        }
        .padding()

        verifyViewInBothColorSchemes(view, named: "TrafficLightIndicator")
    }

    // MARK: - ProgressRing Tests

    func testProgressRing_Empty() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 0)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Text("0%")
                .font(.headline)
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_Empty")
    }

    func testProgressRing_Quarter() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Text("25%")
                .font(.headline)
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_Quarter")
    }

    func testProgressRing_Half() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Text("50%")
                .font(.headline)
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_Half")
    }

    func testProgressRing_ThreeQuarters() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Text("75%")
                .font(.headline)
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_ThreeQuarters")
    }

    func testProgressRing_Full() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 1.0)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_Full")
    }

    func testProgressRing_AllVariations() {
        let view = HStack(spacing: 20) {
            ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { progress in
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress == 1.0 ? Color.green : (progress > 0.5 ? Color.blue : Color.orange),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()

        verifyViewRenders(view, named: "ProgressRing_AllVariations")
    }

    func testProgressRing_BothColorSchemes() {
        let view = ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            Text("65%")
                .font(.headline)
        }
        .padding()

        verifyViewInBothColorSchemes(view, named: "ProgressRing")
    }

    // MARK: - StatCard Variations Tests

    func testStatCard_Volume() {
        let view = VStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.title2)
                .foregroundColor(.purple)

            Text("12.5k lbs")
                .font(.title2)
                .bold()

            Text("Volume")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_Volume")
    }

    func testStatCard_Duration() {
        let view = VStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text("45 min")
                .font(.title2)
                .bold()

            Text("Duration")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_Duration")
    }

    func testStatCard_RPE() {
        let view = VStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.blue)

            Text("7.5")
                .font(.title2)
                .bold()

            Text("Avg RPE")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_RPE")
    }

    func testStatCard_Pain() {
        let view = VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.title2)
                .foregroundColor(.red)

            Text("3.2")
                .font(.title2)
                .bold()

            Text("Avg Pain")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_Pain")
    }

    func testStatCard_Streak() {
        let view = VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)

            Text("14")
                .font(.title2)
                .bold()

            Text("Day Streak")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_Streak")
    }

    func testStatCard_Adherence() {
        let view = VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            Text("95%")
                .font(.title2)
                .bold()

            Text("Adherence")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewRenders(view, named: "StatCard_Adherence")
    }

    func testStatCardGrid_LightMode() {
        let view = LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("12.5k")
                    .font(.title2)
                    .bold()
                Text("Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("45m")
                    .font(.title2)
                    .bold()
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("7.5")
                    .font(.title2)
                    .bold()
                Text("RPE")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("2.0")
                    .font(.title2)
                    .bold()
                Text("Pain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "StatCardGrid_Light")
    }

    func testStatCardGrid_DarkMode() {
        let view = LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("18.2k")
                    .font(.title2)
                    .bold()
                Text("Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("1h 15m")
                    .font(.title2)
                    .bold()
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "StatCardGrid_Dark")
    }

    func testStatCard_BothColorSchemes() {
        let view = VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text("21")
                .font(.title2)
                .bold()
            Text("Day Streak")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()

        verifyViewInBothColorSchemes(view, named: "StatCard")
    }

    // MARK: - Component Comprehensive Gallery

    func testNewComponentsGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: 24) {
                // Traffic Light Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Traffic Light Indicators").font(.headline)
                    HStack(spacing: 16) {
                        ForEach([(Color.red, "xmark.octagon.fill"),
                                 (Color.yellow, "exclamationmark.triangle.fill"),
                                 (Color.green, "checkmark.circle.fill")], id: \.0) { (color, icon) in
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(color)
                                    .frame(width: 28, height: 28)
                                Image(systemName: icon)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }

                // Progress Ring Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress Rings").font(.headline)
                    HStack(spacing: 16) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { progress in
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                }

                // Stat Cards Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stat Cards").font(.headline)
                    HStack(spacing: 12) {
                        VStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("14")
                                .fontWeight(.bold)
                            Text("Streak")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)

                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("95%")
                                .fontWeight(.bold)
                            Text("Adherence")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(width: 350)
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "NewComponentsGallery_Light")
    }

    func testNewComponentsGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: 24) {
                // Traffic Light Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Traffic Light Indicators").font(.headline)
                    HStack(spacing: 16) {
                        ForEach([(Color.red, "xmark.octagon.fill"),
                                 (Color.yellow, "exclamationmark.triangle.fill"),
                                 (Color.green, "checkmark.circle.fill")], id: \.0) { (color, icon) in
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(color)
                                    .frame(width: 28, height: 28)
                                Image(systemName: icon)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }

                // Progress Ring Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress Rings").font(.headline)
                    HStack(spacing: 16) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { progress in
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                }

                // Stat Cards Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stat Cards").font(.headline)
                    HStack(spacing: 12) {
                        VStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("21")
                                .fontWeight(.bold)
                            Text("Streak")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)

                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("100%")
                                .fontWeight(.bold)
                            Text("Adherence")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(width: 350)
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "NewComponentsGallery_Dark")
    }
}
