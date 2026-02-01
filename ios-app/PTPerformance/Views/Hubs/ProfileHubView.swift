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

    // MARK: - State

    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()

    // MARK: - Computed Properties

    /// Current subscription plan display text
    private var subscriptionPlanText: String {
        if storeKit.isPremium {
            if storeKit.purchasedProductIDs.contains("com.ptperformance.app.annual") {
                return "Annual Premium"
            } else if storeKit.purchasedProductIDs.contains("com.ptperformance.app.monthly") {
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
        }
    }

    // MARK: - Health Section (Premium Features)

    private var healthSection: some View {
        Section("Health & Wellness") {
            // Nutrition
            NavigationLink {
                premiumGatedView(
                    premium: { NutritionTabView() },
                    locked: { PremiumLockedView(feature: "Nutrition", icon: "fork.knife", description: "Meal plans, food tracking, and nutrition guidance") }
                )
            } label: {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("Nutrition")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }

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
                        Text("Readiness")
                            .foregroundColor(.primary)
                        Spacer()
                        premiumBadgeIfNeeded
                    }
                }
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
                    Text("Body Composition")
                        .foregroundColor(.primary)
                }
            }

            NavigationLink {
                BodyCompGoalsView()
            } label: {
                HStack {
                    Image(systemName: "figure.arms.open")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("Body Comp Goals")
                        .foregroundColor(.primary)
                }
            }

            NavigationLink {
                CalculatorsMenuView()
            } label: {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("Calculators")
                        .foregroundColor(.primary)
                }
            }

            NavigationLink {
                PatientGoalsView()
            } label: {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("My Goals")
                        .foregroundColor(.primary)
                }
            }
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
            }
            .padding(.vertical, 4)

            // Primary metrics for current mode
            HStack(spacing: 12) {
                ForEach(modeService.currentMode.primaryMetrics, id: \.self) { metric in
                    Text(metric)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Therapist Section

    private var therapistSection: some View {
        Section("Therapist") {
            NavigationLink {
                TherapistLinkingView()
            } label: {
                HStack {
                    Image(systemName: therapistLinkingVM.isLinked ? "person.2.fill" : "person.badge.plus")
                        .foregroundColor(therapistLinkingVM.isLinked ? .green : .blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Therapist Linking")
                            .foregroundColor(.primary)
                        Text(therapistLinkStatusText)
                            .font(.caption)
                            .foregroundColor(therapistLinkingVM.isLinked ? .green : .secondary)
                    }
                }
            }
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
                    Text("AI Assistant")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }

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
                    Text("Learn")
                        .foregroundColor(.primary)
                    Spacer()
                    premiumBadgeIfNeeded
                }
            }

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

            // Privacy Notice
            NavigationLink {
                PrivacyNoticeView(onAccept: {})
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Privacy Notice")
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section("Subscription") {
            NavigationLink {
                SubscriptionView()
                    .environmentObject(StoreKitService.shared)
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage Subscription")
                            .foregroundColor(.primary)
                        Text(subscriptionPlanText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
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
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }
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
                    Text("Premium Features")
                }
            }
            .accessibilityLabel("Premium Features")
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
            print("Logout error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileHubView()
        .environmentObject(StoreKitService.shared)
        .environmentObject(AppState())
}
