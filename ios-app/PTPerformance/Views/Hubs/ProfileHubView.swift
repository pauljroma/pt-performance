// DARK MODE: See ModeThemeModifier.swift for central theme control
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
/// Uses staggered entrance animations for enhanced visual feedback
struct ProfileHubView: View {
    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState
    @StateObject private var supabase = PTSupabaseClient.shared
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @StateObject private var modeService = ModeService.shared
    @AppStorage("hasCompletedQuickSetup") private var hasCompletedQuickSetup = false

    // MARK: - State

    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    @State private var showQuickSetup = false
    @State private var showModeChanger = false
    @State private var isSavingMode = false

    // Animation state for staggered section reveal
    @State private var sectionsVisible = false

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
                // Profile header with mode indicator - hero section
                profileHeaderSection
                    .staggeredAnimation(index: 0)

                // Quick Access to Settings - ACP-1036
                quickSettingsSection
                    .staggeredAnimation(index: 1)

                // Achievement Showcase
                if let patientIdString = supabase.userId,
                   let patientId = UUID(uuidString: patientIdString) {
                    Section {
                        AchievementShowcaseView(patientId: patientId)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    .staggeredAnimation(index: 2)
                }

                // Health Section (Premium features consolidated here)
                healthSection
                    .staggeredAnimation(index: 3)

                // Tools & Tracking
                toolsSection
                    .staggeredAnimation(index: 4)

                // Training Mode (gated by MVP flag)
                if Config.MVPConfig.modeSelectionEnabled {
                    trainingModeSection
                        .staggeredAnimation(index: 5)
                }

                // Therapist Section (gated by MVP flag)
                if Config.MVPConfig.therapistLinkingEnabled {
                    therapistSection
                        .staggeredAnimation(index: 6)
                }

                // Support Section
                supportSection
                    .staggeredAnimation(index: 7)

                // Subscription Section
                subscriptionSection
                    .staggeredAnimation(index: 8)

                // Account Section
                accountSection
                    .staggeredAnimation(index: 9)

                // Debug Section
                debugSection
                    .staggeredAnimation(index: 10)
            }
            .navigationTitle("Profile")
            .task {
                await therapistLinkingVM.checkLinkStatus()
            }
            .fullScreenCoverWithHaptic(isPresented: $showQuickSetup) {
                QuickSetupView()
            }
        }
    }

    // MARK: - Quick Settings Section (ACP-1036)

    /// Quick access to unified settings
    private var quickSettingsSection: some View {
        Section {
            NavigationLink {
                UnifiedSettingsView()
                    .environmentObject(storeKit)
                    .environmentObject(appState)
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.modusCyan)
                        .font(.title2)
                        .frame(width: 32)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Manage account, preferences, and data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, Spacing.xs)
                .accessibilityIdentifier("profile_hub_settings_link")
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Manage account, preferences, health data, and more")
        }
    }

    // MARK: - Profile Header Section

    /// Hero header section with user mode and status
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                // Mode icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [modeThemeColor.opacity(0.8), modeThemeColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: modeService.currentMode.iconName)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(modeService.currentMode.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subscriptionPlanText)
                        .font(.subheadline)
                        .foregroundColor(storeKit.isPremium ? .green : .secondary)

                    if therapistLinkingVM.isLinked {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("Connected to PT")
                                .font(.caption)
                        }
                        .foregroundColor(.modusCyan)
                    }
                }

                Spacer()
            }
            .padding(.vertical, Spacing.xs)
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
                        .foregroundColor(.modusCyan)
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
                .accessibilityIdentifier("profile_hub_apple_health_link")
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
            // Body Composition tools — gated by MVP flag
            if Config.MVPConfig.bodyCompToolsEnabled {
                NavigationLink {
                    BodyCompositionTimelineView()
                } label: {
                    HStack {
                        Image(systemName: "figure.stand")
                            .foregroundColor(.modusCyan)
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
            }

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
            Button {
                showModeChanger = true
            } label: {
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
                    if isSavingMode {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Training Mode: \(modeService.currentMode.displayName). Tap to change.")

            // Primary metrics for current mode
            HStack(spacing: 12) {
                ForEach(modeService.currentMode.primaryMetrics, id: \.self) { metric in
                    Text(metric)
                        .font(.caption)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.xs)
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Primary metrics: \(modeService.currentMode.primaryMetrics.joined(separator: ", "))")
        }
        .confirmationDialog("Change Training Mode", isPresented: $showModeChanger, titleVisibility: .visible) {
            ForEach(Mode.allCases, id: \.self) { mode in
                Button(mode.displayName) {
                    Task { await changeMode(to: mode) }
                }
                .disabled(mode == modeService.currentMode)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you want to train. This changes your dashboard and tracked metrics.")
        }
    }

    private func changeMode(to newMode: Mode) async {
        guard newMode != modeService.currentMode else { return }
        guard let authUserId = PTSupabaseClient.shared.authUserId else { return }

        isSavingMode = true
        defer { isSavingMode = false }

        do {
            try await PTSupabaseClient.shared.client
                .from("patients")
                .update(["mode": newMode.rawValue])
                .eq("user_id", value: authUserId)
                .execute()

            await modeService.loadPatientMode()
            HapticFeedback.formSubmission(success: true)
            ErrorLogger.shared.logUserAction(
                action: "mode_changed",
                properties: ["new_mode": newMode.rawValue]
            )
        } catch {
            HapticFeedback.formSubmission(success: false)
            ErrorLogger.shared.logError(
                error,
                context: "ProfileHub mode change to \(newMode.rawValue)"
            )
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
                            .foregroundColor(therapistLinkingVM.isLinked ? .green : .modusCyan)
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
                        .foregroundColor(.modusCyan)
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
                        .foregroundColor(.modusCyan)
                        .frame(width: 24)
                    Text("View Tutorial")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("View Tutorial")
            .accessibilityHint("Replays the app introduction walkthrough")

            // Quick Setup
            Button {
                HapticFeedback.light()
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
                        .foregroundColor(.modusCyan)
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

            // Baseball Pack — gated by feature flag
            if Config.AIConfig.baseballPackEnabled {
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
                                .cornerRadius(CornerRadius.xs)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityLabel("Baseball Pack")
                .accessibilityValue(storeKit.hasBaseballAccess ? "Purchased" : "Not purchased")
                .accessibilityHint("12 or more baseball training programs")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            Button {
                HapticFeedback.medium()
                Task {
                    await logout()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.modusCyan)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Log Out")
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Log Out")
            .accessibilityHint("Signs you out of the app")
            .accessibilityIdentifier("profile_hub_log_out_button")

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

    @AppStorage("debug_demo_mode") private var debugDemoMode = false

    private var debugSection: some View {
        Section("Debug") {
            Toggle(isOn: Binding(
                get: { storeKit.debugPremiumOverride ?? false },
                set: { newValue in
                    HapticFeedback.toggle()
                    storeKit.debugPremiumOverride = newValue
                }
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
                    HapticFeedback.light()
                    storeKit.debugPremiumOverride = nil
                }
                .foregroundColor(.modusCyan)
                .accessibilityLabel("Reset to Real Status")
                .accessibilityHint("Removes debug override and uses actual subscription status")
            }

            // Demo Mode Toggle for X2 Command Center testing
            Toggle(isOn: Binding(
                get: { debugDemoMode },
                set: { newValue in
                    HapticFeedback.toggle()
                    debugDemoMode = newValue
                }
            )) {
                HStack {
                    Image(systemName: debugDemoMode ? "play.circle.fill" : "play.circle")
                        .foregroundColor(debugDemoMode ? .cyan : .gray)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Demo Mode")
                        Text("Use sample data for X2 Command Center")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel("Demo Mode")
            .accessibilityValue(debugDemoMode ? "Enabled" : "Disabled")
            .accessibilityHint("Toggle to use demo data instead of live backend data")
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
                .cornerRadius(CornerRadius.xs)
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
