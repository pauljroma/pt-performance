import SwiftUI

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @ObservedObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @ObservedObject private var supabase = PTSupabaseClient.shared
    @ObservedObject private var modeService = ModeService.shared  // ACP-479: Mode awareness
    @StateObject private var therapistLinkingVM = TherapistLinkingViewModel()
    // Use EnvironmentObject to share same instance with PatientTabView
    // Previously @StateObject created separate observation, so toggle didn't update tabs
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var appState: AppState

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

    // ACP-479: Mode theme color
    private var modeThemeColor: Color {
        ModeTheme.theme(for: modeService.currentMode).primaryColor
    }

    // ACP-479: Mode badge text
    private var modeBadgeText: String {
        switch modeService.currentMode {
        case .rehab:
            return "REHAB"
        case .strength:
            return "STRENGTH"
        case .performance:
            return "PERFORMANCE"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Quick wins — Body Comp, Calculators, Goals
                Section("Tools & Tracking") {
                    NavigationLink {
                        BodyCompositionTimelineView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.stand")
                                .foregroundColor(.accentColor)
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
                            Text("My Goals")
                                .foregroundColor(.primary)
                        }
                    }

                    NavigationLink {
                        HealthHubView()
                            .environmentObject(storeKit)
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.cyan)
                            Text("Health Hub")
                                .foregroundColor(.primary)
                        }
                    }
                }

                // ACP-479: Training Mode indicator (PT-controlled)
                Section("Training Mode") {
                    HStack {
                        Image(systemName: modeService.currentMode.iconName)
                            .font(.title2)
                            .foregroundColor(modeThemeColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(modeService.currentMode.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(modeService.currentMode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // Mode badge
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
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section("Help & Support") {
                    Button {
                        onboardingCoordinator.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("View Tutorial")
                    .accessibilityHint("Replays the app introduction walkthrough")
                }

                Section("Privacy & Data") {
                    NavigationLink {
                        PrivacyNoticeView(onAccept: {})
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.accentColor)
                            Text("Privacy Notice")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView()
                            .environmentObject(StoreKitService.shared)
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
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

                Section("Therapist") {
                    NavigationLink {
                        TherapistLinkingView()
                    } label: {
                        HStack {
                            Image(systemName: therapistLinkingVM.isLinked ? "person.2.fill" : "person.badge.plus")
                                .foregroundColor(therapistLinkingVM.isLinked ? .green : .accentColor)
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

                Section("Account") {
                    Button {
                        Task {
                            await logout()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.accentColor)
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
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Toggle(isOn: Binding(
                        get: { storeKit.debugPremiumOverride ?? false },
                        set: { storeKit.debugPremiumOverride = $0 }
                    )) {
                        HStack {
                            Image(systemName: storeKit.isPremium ? "lock.open.fill" : "lock.fill")
                                .foregroundColor(storeKit.isPremium ? .green : .gray)
                                .accessibilityHidden(true)
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
                        .foregroundColor(.accentColor)
                        .accessibilityLabel("Reset to Real Status")
                        .accessibilityHint("Removes debug override and uses actual subscription status")
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .task {
                // Fetch therapist link status on view appear
                await therapistLinkingVM.checkLinkStatus()
            }
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
            DebugLogger.shared.error("PatientSettingsView", "Logout error: \(error.localizedDescription)")
        }
    }
}
