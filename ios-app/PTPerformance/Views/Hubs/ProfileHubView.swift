//
//  ProfileHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Profile Hub
//  Unified profile tab with settings and navigation to premium features
//

import SwiftUI

/// Profile Hub View - Unified settings and features tab
/// Provides organized access to Settings, Health features, and Support
struct ProfileHubView: View {
    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var modeService = ModeService.shared
    @AppStorage("hasCompletedQuickSetup") private var hasCompletedQuickSetup = false

    // MARK: - State

    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    @State private var showQuickSetup = false

    // MARK: - Computed Properties

    /// Current subscription plan display text
    private var subscriptionPlanText: String {
        if storeKit.isPremium {
            if storeKit.purchasedProductIDs.contains("com.getmodus.app.annual") {
                return "Annual Premium"
            } else if storeKit.purchasedProductIDs.contains("com.getmodus.app.monthly") {
                return "Monthly Premium"
            } else {
                return "Premium Active"
            }
        } else {
            return "Free Plan"
        }
    }

    /// Therapist link status display text
    private var therapistLinkStatusText: String {
        if therapistLinkingVM.isLinked {
            return therapistLinkingVM.therapistName ?? "Linked"
        } else {
            return "Not linked"
        }
    }

    /// Mode theme color
    private var modeThemeColor: Color {
        ModeTheme.theme(for: modeService.currentMode).primaryColor
    }

    /// Mode badge text
    private var modeBadgeText: String {
        switch modeService.currentMode {
        case .rehab:
            return "PT-SET"
        case .strength:
            return "PT-SET"
        case .performance:
            return "PT-SET"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Health Section (Premium features consolidated here)
                healthSection

                // Tools & Tracking
                toolsSection

                // Training Mode
                trainingModeSection

                // Therapist Section
                therapistSection

                // Support Section
                supportSection

                // Subscription Section
                subscriptionSection

                // Account Section
                accountSection

                // Debug Section
                debugSection
            }
            .navigationTitle("Profile")
            .task {
                await therapistLinkingVM.checkLinkStatus()
            }
            .fullScreenCover(isPresented: $showQuickSetup) {
                QuickSetupView()
            }
        }
    }

    // MARK: - State for HealthKit

    @StateObject private var healthKitService = HealthKitService.shared

    // MARK: - Health Section (Premium Features)

    private var healthSection: some View {
        Section("Health & Wellness") {
            // Smart Notifications (ACP-841)
            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Notifications")
                            .foregroundColor(.primary)
                        Text("Workout reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel("Smart Notifications")
            .accessibilityHint("Configure workout reminder settings")

            // Apple Health Sync
            NavigationLink {
                HealthKitSettingsView()
                    .environmentObject(healthKitService)
            } label: {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .foregroundColor(.primary)
                        Text(healthKitService.isAuthorized ? "Connected" : "Not connected")
                            .font(.caption)
                            .foregroundColor(healthKitService.isAuthorized ? .green : .secondary)
                    }
                }
            }
            .accessibilityLabel("Apple Health")
            .accessibilityValue(healthKitService.isAuthorized ? "Connected" : "Not connected")
            .accessibilityHint("Configure Apple Health integration")

            // Nutrition
            NavigationLink {
                premiumGatedView(
                    premium: { ModusNutritionDashboardView() },
                    locked: { PremiumLockedView(feature: "Nutrition", icon: "fork.knife", description: "Personalized nutrition targets, meal tracking, and portion guides") }
                )
            } label: {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.green)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Nutrition")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }
            .accessibilityLabel("Nutrition" + (storeKit.isPremium ? "" : ", Premium feature"))
            .accessibilityHint("Personalized nutrition targets, meal tracking, and portion guides")

            // Readiness
            if let patientIdString = supabase.userId,
               let patientId = UUID(uuidString: patientIdString) {
                NavigationLink {
                    premiumGatedView(
                        premium: { ReadinessCheckInView(patientId: patientId) },
                        locked: { PremiumLockedView(feature: "Readiness", icon: "battery.100", description: "Daily readiness check-ins and recovery scoring") }
                    )
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Readiness")
                            .foregroundColor(.primary)
                        Spacer()
                        premiumBadgeIfNeeded
                    }
                }
                .accessibilityLabel("Readiness" + (storeKit.isPremium ? "" : ", Premium feature"))
                .accessibilityHint("Daily readiness check-ins and recovery scoring")

                // Recovery Status (Deload Recommendations)
                NavigationLink {
                    premiumGatedView(
                        premium: { DeloadRecommendationView(patientId: patientId) },
                        locked: { PremiumLockedView(feature: "Recovery", icon: "bed.double.fill", description: "Smart deload recommendations based on your fatigue and training load") }
                    )
                } label: {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Recovery Status")
                            .foregroundColor(.primary)
                        Spacer()
                        premiumBadgeIfNeeded
                    }
                }
                .accessibilityLabel("Recovery Status" + (storeKit.isPremium ? "" : ", Premium feature"))
                .accessibilityHint("Smart deload recommendations based on your fatigue and training load")
            }
        }
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        Section("Tools & Tracking") {
            NavigationLink {
                BodyCompositionTimelineView()
            } label: {
                HStack {
                    Image(systemName: "figure.stand")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Body Composition")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Body Composition")
            .accessibilityHint("Track body measurements over time")

            NavigationLink {
                BodyCompGoalsView()
            } label: {
                HStack {
                    Image(systemName: "figure.arms.open")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Body Comp Goals")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Body Comp Goals")
            .accessibilityHint("Set body composition targets")

            NavigationLink {
                CalculatorsMenuView()
            } label: {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.green)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Calculators")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Calculators")
            .accessibilityHint("Access fitness and training calculators")

            NavigationLink {
                PatientGoalsView()
            } label: {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("My Goals")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("My Goals")
            .accessibilityHint("View and manage your fitness goals")
        }
    }

    // MARK: - Training Mode Section

    private var trainingModeSection: some View {
        Section("Training Mode") {
            HStack {
                Image(systemName: modeService.currentMode.iconName)
                    .font(.title2)
                    .foregroundColor(modeThemeColor)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(modeService.currentMode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(modeService.currentMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(modeBadgeText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(modeThemeColor.opacity(0.15))
                    .foregroundColor(modeThemeColor)
                    .cornerRadius(4)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Training Mode: \(modeService.currentMode.displayName). \(modeService.currentMode.description)")

            // Primary metrics for current mode
            HStack(spacing: 12) {
                ForEach(modeService.currentMode.primaryMetrics, id: \.self) { metric in
                    Text(metric)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Primary metrics: \(modeService.currentMode.primaryMetrics.joined(separator: ", "))")
        }
    }

    // MARK: - Therapist Section

    private var therapistSection: some View {
        Section("Therapist") {
            NavigationLink {
                TherapistLinkingView()
            } label: {
                HStack {
                    if therapistLinkingVM.isLoading {
                        ProgressView()
                            .frame(width: 24)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: therapistLinkingVM.isLinked ? "person.2.fill" : "person.badge.plus")
                            .foregroundColor(therapistLinkingVM.isLinked ? .green : .blue)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Therapist Linking")
                            .foregroundColor(.primary)
                        if therapistLinkingVM.isLoading {
                            Text("Checking...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(therapistLinkStatusText)
                                .font(.caption)
                                .foregroundColor(therapistLinkingVM.isLinked ? .green : .secondary)
                        }
                    }
                }
            }
            .accessibilityLabel("Therapist Linking")
            .accessibilityValue(therapistLinkingVM.isLoading ? "Checking status" : therapistLinkStatusText)
            .accessibilityHint("Connect with your physical therapist")
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section("Support & Learning") {
            // AI Assistant
            NavigationLink {
                premiumGatedView(
                    premium: { AIChatView() },
                    locked: { PremiumLockedView(feature: "AI Assistant", icon: "brain.head.profile", description: "AI-powered exercise recommendations and coaching") }
                )
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("AI Assistant")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }
            .accessibilityLabel("AI Assistant" + (storeKit.isPremium ? "" : ", Premium feature"))
            .accessibilityHint("AI-powered exercise recommendations and coaching")

            // Learn
            NavigationLink {
                premiumGatedView(
                    premium: { HelpView() },
                    locked: { PremiumLockedView(feature: "Learn", icon: "book.fill", description: "Educational content and exercise technique guides") }
                )
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Learn")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }
            .accessibilityLabel("Learn" + (storeKit.isPremium ? "" : ", Premium feature"))
            .accessibilityHint("Educational content and exercise technique guides")

            // Tutorial
            Button {
                onboardingCoordinator.resetOnboarding()
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("View Tutorial")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("View Tutorial")
            .accessibilityHint("Replays the app introduction walkthrough")

            // Quick Setup
            Button {
                showQuickSetup = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.modusCyan)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Setup")
                            .foregroundColor(.primary)
                        Text(hasCompletedQuickSetup ? "Redo configuration" : "Configure your account")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel("Quick Setup")
            .accessibilityHint(hasCompletedQuickSetup ? "Redo your mode, goals, and preferences configuration" : "Configure your mode, goals, and initial preferences")

            // Privacy Notice
            NavigationLink {
                PrivacyNoticeView(onAccept: {})
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Privacy Notice")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Privacy Notice")
            .accessibilityHint("View the app privacy policy")
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section("Subscription & Purchases") {
            // Main subscription
            NavigationLink {
                SubscriptionView()
                    .environmentObject(StoreKitService.shared)
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage Subscription")
                            .foregroundColor(.primary)
                        Text(subscriptionPlanText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel("Manage Subscription")
            .accessibilityValue(subscriptionPlanText)
            .accessibilityHint("View and manage your subscription plan")

            // Baseball Pack
            NavigationLink {
                BaseballPackView()
                    .environmentObject(storeKit)
            } label: {
                HStack {
                    Image(systemName: "baseball.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Baseball Pack")
                            .foregroundColor(.primary)
                        Text(storeKit.hasBaseballAccess ? "Purchased" : "12+ baseball programs")
                            .font(.caption)
                            .foregroundColor(storeKit.hasBaseballAccess ? .green : .secondary)
                    }
                    Spacer()
                    if storeKit.hasBaseballAccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    } else {
                        Text("PREMIUM")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityLabel("Baseball Pack")
            .accessibilityValue(storeKit.hasBaseballAccess ? "Purchased" : "Not purchased")
            .accessibilityHint("12 or more baseball training programs")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            Button {
                Task {
                    await logout()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Log Out")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Log Out")
            .accessibilityHint("Signs you out of the app")

            NavigationLink {
                AccountDeletionView()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }
            .accessibilityLabel("Delete Account")
            .accessibilityHint("Permanently delete your account and all data")
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        Section("Debug") {
            Toggle(isOn: Binding(
                get: { storeKit.debugPremiumOverride ?? false },
                set: { storeKit.debugPremiumOverride = $0 }
            )) {
                HStack {
                    Image(systemName: storeKit.isPremium ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(storeKit.isPremium ? .green : .gray)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Premium Features")
                }
            }
            .accessibilityLabel("Premium Features Debug Toggle")
            .accessibilityValue(storeKit.isPremium ? "Enabled" : "Disabled")
            .accessibilityHint("Toggle to test premium features")

            if storeKit.debugPremiumOverride != nil {
                Button("Reset to Real Status") {
                    storeKit.debugPremiumOverride = nil
                }
                .foregroundColor(.blue)
                .accessibilityLabel("Reset to Real Status")
                .accessibilityHint("Removes debug override and uses actual subscription status")
            }
        }
    }

    // MARK: - Premium Badge

    @ViewBuilder
    private var premiumBadgeIfNeeded: some View {
        if !storeKit.isPremium {
            Text("PRO")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(4)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Premium Gated View Helper

    @ViewBuilder
    private func premiumGatedView<Premium: View, Locked: View>(
        @ViewBuilder premium: () -> Premium,
        @ViewBuilder locked: () -> Locked
    ) -> some View {
        if storeKit.isPremium {
            premium()
        } else {
            locked()
                .environmentObject(storeKit)
        }
    }

    // MARK: - Logout

    private func logout() async {
        do {
            try await PTSupabaseClient.shared.signOut()
            await MainActor.run {
                appState.isAuthenticated = false
                appState.userRole = nil
                appState.userId = nil
            }
        } catch {
            DebugLogger.shared.error("ProfileHubView", "Logout failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileHubView()
        .environmentObject(StoreKitService.shared)
        .environmentObject(AppState())
}
