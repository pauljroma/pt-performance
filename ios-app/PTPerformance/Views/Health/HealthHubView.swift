// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  HealthHubView.swift
//  PTPerformance
//
//  Health Hub - Unified entry point for all health features
//  Provides today's snapshot, quick actions, AI insights, and navigation to detailed views
//

import SwiftUI

// MARK: - Health Hub Navigation Destination

/// Centralized navigation destinations for Health Hub
/// Consolidates all navigation state into a single enum
enum HealthHubNavigationDestination: Hashable {
    case fastingTracker
    case supplementDashboard
    case recoveryTracking
    case biomarkerDashboard
    case labResults
    case aiCoach
    case labUpload
    case aiHealthCoach
}

/// Health Hub View - The central dashboard for all health features
/// Aggregates data from Recovery, Fasting, Supplements, and Biomarkers
struct HealthHubView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @StateObject private var viewModel = HealthHubViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Consolidated navigation path for deep linking support
    @State private var navigationPath = NavigationPath()

    // Legacy navigation state for quick actions (kept for backward compatibility with sheets)
    @State private var showFastingTracker = false
    @State private var showSupplementDashboard = false
    @State private var showRecoveryTracking = false
    @State private var showBiomarkerDashboard = false
    @State private var showLabResults = false
    @State private var showAICoach = false
    @State private var showLabUpload = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if !Config.MVPConfig.paywallEnabled || storeKit.isPremium {
                premiumContent
            } else {
                paywallContent
            }
        }
        .tint(.modusCyan)
    }

    // MARK: - Premium Content

    private var premiumContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header with greeting
                headerSection

                // Lab Upload CTA (shown only when no lab results exist)
                if Config.MVPConfig.labUploadEnabled && !viewModel.hasLabResults {
                    labUploadCTACard
                }

                // Today's Health Snapshot Card (using new component)
                healthSnapshotSection

                // Quick Actions Grid (using new component)
                quickActionsGridSection

                // Detailed Views Navigation
                detailedViewsSection
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively) // Keyboard dismissal on scroll
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Health Hub")
        .navigationBarTitleDisplayMode(.large)
        .refreshableWithHaptic {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .onDisappear {
            // Clean up timer when view disappears to prevent memory leaks
            viewModel.pauseTimerUpdates()
        }
        .onAppear {
            // Resume timer updates when view reappears
            viewModel.resumeTimerUpdates()
        }
        // Type-safe navigation destinations for deep linking
        .navigationDestination(for: HealthHubNavigationDestination.self) { destination in
            destinationView(for: destination)
        }
        // Legacy navigation destinations for backward compatibility
        .navigationDestination(isPresented: $showFastingTracker) {
            FastingTrackerView()
        }
        .navigationDestination(isPresented: $showSupplementDashboard) {
            SupplementDashboardView()
        }
        .navigationDestination(isPresented: $showRecoveryTracking) {
            RecoveryTrackingView()
        }
        .navigationDestination(isPresented: $showBiomarkerDashboard) {
            BiomarkerDashboardView()
        }
        .navigationDestination(isPresented: $showLabResults) {
            LabResultsView()
        }
        .navigationDestination(isPresented: $showAICoach) {
            UnifiedAICoachView()
        }
        .navigationDestination(isPresented: $showLabUpload) {
            LabPDFUploadView()
        }
    }

    // MARK: - Navigation Destination Builder

    @ViewBuilder
    private func destinationView(for destination: HealthHubNavigationDestination) -> some View {
        switch destination {
        case .fastingTracker:
            FastingTrackerView()
        case .supplementDashboard:
            SupplementDashboardView()
        case .recoveryTracking:
            RecoveryTrackingView()
        case .biomarkerDashboard:
            BiomarkerDashboardView()
        case .labResults:
            LabResultsView()
        case .aiCoach:
            UnifiedAICoachView()
        case .labUpload:
            LabPDFUploadView()
        case .aiHealthCoach:
            AIHealthCoachView()
        }
    }

    // MARK: - Deep Linking Support

    /// Navigate to a specific destination programmatically
    /// Useful for deep linking and cross-feature navigation
    func navigate(to destination: HealthHubNavigationDestination) {
        navigationPath.append(destination)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }

            Spacer()

            // Health Score Badge
            Group {
                if Config.MVPConfig.aiHealthCoachEnabled {
                    NavigationLink {
                        AIHealthCoachView()
                    } label: {
                        healthScoreBadgeLabel
                    }
                    .accessibilityHint("Double tap to view detailed health insights")
                } else {
                    healthScoreBadgeLabel
                }
            }
            .accessibilityLabel("Health score \(viewModel.recoveryScore) percent")
            .accessibilityIdentifier("healthScoreBadge")
        }
        .accessibilityElement(children: .contain)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    // MARK: - Lab Upload CTA Card

    private var healthScoreBadgeLabel: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: Double(viewModel.recoveryScore) / 100)
                    .stroke(viewModel.recoveryStatusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))

                Text("\(viewModel.recoveryScore)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)
            }
            .accessibilityHidden(true)

            Text("Score")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    private var labUploadCTACard: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Upload Your Lab Results")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Text("Get AI-powered insights from your blood work")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button {
                showLabUpload = true
            } label: {
                Text("Upload PDF")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44) // Minimum touch target
                    .padding(.vertical, Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [.modusCyan, .modusTealAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
            }
            .accessibilityLabel("Upload PDF")
            .accessibilityHint("Double tap to upload your lab results PDF")
            .accessibilityIdentifier("labUploadButton")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Health Snapshot Section (Using New Component)

    private var healthSnapshotSection: some View {
        HealthSnapshotCard(
            data: HealthSnapshotData(
                recoveryScore: viewModel.recoveryScore,
                recoveryTrend: recoveryTrend,
                fastingStatus: Config.MVPConfig.fastingTrackerEnabled ? HealthSnapshotData.FastingStatus(
                    isFasting: viewModel.isFasting,
                    hoursElapsed: fastingHoursElapsed,
                    targetHours: fastingTargetHours,
                    currentProtocol: nil
                ) : HealthSnapshotData.FastingStatus(
                    isFasting: false,
                    hoursElapsed: nil,
                    targetHours: nil,
                    currentProtocol: nil
                ),
                supplementsCompliance: FeatureFlagService.shared.isEnabled("supplements_enabled")
                    ? HealthSnapshotData.SupplementsCompliance(
                        taken: viewModel.supplementsTaken,
                        total: viewModel.supplementsTotal
                    )
                    : HealthSnapshotData.SupplementsCompliance(taken: 0, total: 0),
                labAlerts: 0,
                lastUpdated: Date()
            ),
            isLoading: viewModel.isLoading,
            onRecoveryTap: { showRecoveryTracking = true },
            onFastingTap: Config.MVPConfig.fastingTrackerEnabled
                ? { showFastingTracker = true }
                : nil,
            onSupplementsTap: FeatureFlagService.shared.isEnabled("supplements_enabled")
                ? { showSupplementDashboard = true }
                : nil,
            onLabAlertsTap: nil
        )
    }

    private var recoveryTrend: HealthSnapshotData.TrendDirection {
        if viewModel.hasRecoveredToday && viewModel.recoveryStreak > 2 {
            return .improving
        } else if viewModel.recoveryStreak > 0 {
            return .stable
        } else {
            return .declining
        }
    }

    private var fastingHoursElapsed: Double? {
        guard viewModel.isFasting else { return nil }
        // Parse elapsed time from "HH:MM" format
        let components = viewModel.fastingElapsedTime.split(separator: ":")
        guard components.count >= 2,
              let hours = Double(components[0]),
              let minutes = Double(components[1]) else {
            return nil
        }
        return hours + (minutes / 60.0)
    }

    private var fastingTargetHours: Int? {
        guard viewModel.isFasting else { return nil }
        // Parse target time from "HH:00" format
        let components = viewModel.fastingTargetTime.split(separator: ":")
        if let hours = components.first, let target = Int(hours) {
            return target
        }
        return 16
    }

    // MARK: - Quick Actions Grid Section (Using New Component)

    private var quickActionsGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            QuickActionGrid(
                actions: QuickActionGrid.defaultActions,
                onAction: handleQuickAction
            )
        }
        .accessibilityIdentifier("health_hub_quick_actions")
    }

    private func handleQuickAction(_ action: QuickAction.QuickActionType) {
        switch action {
        case .startFast:
            if Config.MVPConfig.fastingTrackerEnabled {
                showFastingTracker = true
            }
        case .logSupplements:
            if FeatureFlagService.shared.isEnabled("supplements_enabled") {
                showSupplementDashboard = true
            }
        case .logRecovery:
            showRecoveryTracking = true
        case .viewLabs:
            break // Labs coming soon
        case .viewBiomarkers:
            break // Biomarkers coming soon
        case .aiCoach:
            showAICoach = true
        }
    }

    // MARK: - AI Insights Section (Using New Component)

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                NavigationLink {
                    UnifiedAICoachView()
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .accessibilityAddTraits(.isHeader)

            HealthInsightCard(
                insight: HealthHubInsight(
                    type: insightType,
                    category: insightCategory,
                    title: insightTitle,
                    message: viewModel.dailyInsight,
                    actionText: "View Details",
                    action: { showAICoach = true }
                )
            )
        }
    }

    private var insightType: HealthInsightType {
        // Determine insight type based on icon
        switch viewModel.insightIcon {
        case "exclamationmark.triangle.fill":
            return .warning
        case "checkmark.circle.fill":
            return .positive
        case "flame.fill", "trophy.fill", "clock.fill":
            return .info
        default:
            return .info
        }
    }

    private var insightCategory: HealthInsightCategory {
        // Determine category based on icon
        switch viewModel.insightIcon {
        case "flame.fill":
            return .recovery
        case "clock.fill":
            return .fasting
        case "pill.fill":
            return .supplements
        case "exclamationmark.triangle.fill":
            return .biomarkers
        default:
            return .general
        }
    }

    private var insightTitle: String {
        switch viewModel.insightIcon {
        case "flame.fill":
            return "Recovery Streak"
        case "clock.fill":
            return "Fasting Progress"
        case "pill.fill":
            return "Supplements Due"
        case "exclamationmark.triangle.fill":
            return "Biomarkers Alert"
        case "checkmark.circle.fill":
            return "Great Progress"
        case "trophy.fill":
            return "Achievement"
        default:
            return "Daily Insight"
        }
    }

    // Legacy support for existing snapshot row
    private var supplementStatus: HealthSnapshotItem.SnapshotStatus {
        if viewModel.supplementsTotal == 0 {
            return .neutral
        } else if viewModel.supplementComplianceRate >= 1.0 {
            return .good
        } else if viewModel.supplementComplianceRate >= 0.5 {
            return .warning
        } else {
            return .needsAttention
        }
    }

    // MARK: - Legacy Quick Actions Section (kept for reference)

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                LegacyQuickActionButton(
                    title: "Fast",
                    icon: "timer",
                    gradientColors: [.orange, .red.opacity(0.8)],
                    destination: .fastingTracker
                )

                LegacyQuickActionButton(
                    title: "Supps",
                    icon: "pill.fill",
                    gradientColors: [.purple, .indigo],
                    destination: .supplements
                )

                LegacyQuickActionButton(
                    title: "Recov",
                    icon: "snowflake",
                    gradientColors: [.cyan, .modusCyan],
                    destination: .recovery
                )

                ComingSoonQuickActionButton(
                    title: "Labs",
                    icon: "drop.fill"
                )
            }
        }
    }

    // MARK: - Legacy Daily Insight Card (kept for reference)

    private var dailyInsightCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                Text("Today's Insight")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }
            .accessibilityAddTraits(.isHeader)

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: viewModel.insightIcon)
                    .font(.title2)
                    .foregroundColor(.modusCyan)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                Text(viewModel.dailyInsight)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.modusCyan.opacity(0.1), Color.modusTealAccent.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's insight: \(viewModel.dailyInsight)")
    }

    // MARK: - Detailed Views Section

    private var detailedViewsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Detailed Views")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Recovery & Readiness — always visible (MVP core)
                DetailedViewRow(
                    title: "Recovery & Readiness",
                    subtitle: "Sauna, cold plunge, contrast therapy",
                    icon: "heart.circle.fill",
                    iconColor: .pink,
                    destination: RecoveryTrackingView()
                )

                // Supplements — gated by feature flag
                if FeatureFlagService.shared.isEnabled("supplements_enabled") {
                    Divider()
                        .padding(.leading, 56)

                    DetailedViewRow(
                        title: "Supplements",
                        subtitle: "Daily stack and compliance",
                        icon: "pills.circle.fill",
                        iconColor: .purple,
                        destination: SupplementDashboardView()
                    )
                }

                // Fasting Tracker — gated by feature flag
                if Config.MVPConfig.fastingTrackerEnabled {
                    Divider()
                        .padding(.leading, 56)

                    DetailedViewRow(
                        title: "Fasting Tracker",
                        subtitle: "Intermittent fasting protocols",
                        icon: "timer.circle.fill",
                        iconColor: .orange,
                        destination: FastingTrackerView()
                    )
                }

                // Biomarkers & Labs — gated by feature flag
                if Config.MVPConfig.biomarkerDashboardEnabled {
                    Divider()
                        .padding(.leading, 56)

                    DetailedViewRow(
                        title: "Biomarkers & Labs",
                        subtitle: "Track your health markers",
                        icon: "cross.circle.fill",
                        iconColor: .red,
                        destination: BiomarkerDashboardView()
                    )
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Paywall Content

    private var paywallContent: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Hero Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.modusCyan.opacity(0.2), Color.modusTealAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modusCyan, .modusTealAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text("Health Hub")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                Text("Your complete health intelligence center")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Feature List
            VStack(alignment: .leading, spacing: Spacing.md) {
                PaywallFeatureRow(icon: "heart.fill", text: "Recovery Protocol Tracking", color: .pink)
                PaywallFeatureRow(icon: "timer", text: "Intermittent Fasting", color: .orange)
                PaywallFeatureRow(icon: "pill.fill", text: "Supplement Management", color: .purple)
                PaywallFeatureRow(icon: "chart.bar.doc.horizontal", text: "Biomarker Dashboard", color: .red)
                PaywallFeatureRow(icon: "sparkles", text: "AI Health Insights", color: .modusCyan)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
            .padding(.horizontal)

            Spacer()

            // CTA Button
            NavigationLink {
                SubscriptionView()
                    .environmentObject(StoreKitService.shared)
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Upgrade to Premium")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal)
            .accessibilityLabel("Upgrade to Premium")
            .accessibilityHint("Unlock all Health Hub features")

            Spacer()
        }
        .navigationTitle("Health Hub")
    }
}

// MARK: - Snapshot Row

private struct SnapshotRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let status: HealthSnapshotItem.SnapshotStatus
    var statusIcon: String? = nil
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            // Progress bar (if applicable)
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(iconColor)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(width: 50, height: 6)
                .accessibilityHidden(true)
            }

            // Value
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Status Icon
            if let statusIcon = statusIcon {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(status.indicatorColor)
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(status.indicatorColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Legacy Quick Action Button (for backward compatibility)

private struct LegacyQuickActionButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let destination: HealthHubDestination

    @State private var isPressed = false

    var body: some View {
        NavigationLink {
            destinationView
        } label: {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(title)
        .accessibilityHint("Opens \(title) feature")
    }

    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case .fastingTracker:
            FastingTrackerView()
        case .supplements:
            SupplementDashboardView()
        case .recovery:
            RecoveryTrackingView()
        case .biomarkers:
            BiomarkerDashboardView()
        case .labResults:
            LabResultsView()
        case .nutrition:
            ModusNutritionDashboardView()
        case .aiCoach:
            UnifiedAICoachView()
        }
    }
}

// MARK: - Coming Soon Quick Action Button

private struct ComingSoonQuickActionButton: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .overlay(alignment: .topTrailing) {
                Text("Soon")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.gray)
                    .cornerRadius(4)
                    .offset(x: 4, y: -4)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityLabel("\(title), coming soon")
    }
}

// MARK: - Detailed View Row

private struct DetailedViewRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(minHeight: 44) // Minimum touch target
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(subtitle.lowercased())")
        .accessibilityIdentifier("detailedViewRow_\(title.replacingOccurrences(of: " ", with: "_"))")
    }
}

// MARK: - Paywall Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), included in premium")
    }
}

// MARK: - Preview

#if DEBUG
struct HealthHubView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HealthHubView()
                .environmentObject(StoreKitService.shared)
                .previewDisplayName("Premium")

            HealthHubView()
                .environmentObject(StoreKitService.shared)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
